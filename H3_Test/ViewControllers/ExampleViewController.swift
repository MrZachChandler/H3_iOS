//
//  ExampleViewController.swift
//  H3_Test
//
//  Created by Zachary Chandler on 1/26/20.
//  Copyright © 2020 Routematch Software, Inc. All rights reserved.
//

import Foundation
import Mapbox
import SnapKit
import Eureka
import Turf
import H3Swift

class ExampleViewController: FormViewController, H3MapDelegate {
    var resolution: Int32 = 4
    var mapView: MGLMapView!
    var hexLayers: [MGLStyleLayer]?
    var clusterLayer: [MGLStyleLayer]?
    var hubsLayer: MGLStyleLayer?
    var icon: UIImage!
    var popup: UIView?
    var activity: UIActivityIndicatorView?
    var actView: UIView?
    var isLoading = false
    var example: Example! { didSet { title = example.title }}
    var curLocation: CLLocation? {
        didSet {
            if oldValue == nil {
                animateTo(location: curLocation)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        icon = UIImage(named: "port")
        Style.shared.updateUIPreference()
        addMapView()
        LocationManager.sharedManager.registerDelegate(self)
    }
    
    deinit {
        LocationManager.sharedManager.unregisterDelegate(self)
    }
    
    func addMapView() {
        mapView = MGLMapView(frame: view.bounds)
        mapView.delegate = self
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.showsUserHeadingIndicator = true
        mapView.styleURL = Style.shared.preference.mapStyle
        view.addSubview(mapView)
        
        mapView.snp.makeConstraints { make in
            make.top.bottom.right.equalToSuperview()
            make.width.equalTo(view.frame.width - (view.frame.width / 3))
        }
        
        tableView.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.right.equalTo(mapView.snp.left)
        }
        
        view.setNeedsLayout()
        view.setNeedsDisplay()
        
        if let loc = curLocation {
            mapView.setCenter(loc.coordinate, animated: true)
        }
    }

    func startLoading() {
        if activity == nil {
            activity = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
            actView = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
            actView?.backgroundColor = .white
            actView?.alpha = 0
            actView?.addSubview(activity!)
            activity?.startAnimating()
            activity?.snp.makeConstraints({ (make) in
                make.center.equalTo((actView?.snp.center)!)
            })

            view.addSubview(actView!)
            
            actView?.snp.makeConstraints({ (make) in
                make.center.equalToSuperview()
            })
        
            view.bringSubviewToFront(actView!)
            
            UIView.animate(withDuration: 2) {
                self.actView?.alpha = 1
            }
        }
    }
    
    func stopLoading() {
        isLoading = false
        UIView.animate(withDuration: 2) {
            self.actView?.alpha = 0
        }
        
        activity?.stopAnimating()
        activity?.removeFromSuperview()
        activity = nil
        
        actView?.removeFromSuperview()
        actView = nil
    }
    
    func renderHexer(layer :  [H3Index : Double], style: MGLStyle, sourceId: String = "hex_linear", addLineLayer: Bool = false) {
        if hexLayers == nil { hexLayers = [] }
        var features : [FeatureVariant] = []
        
        layer.forEach { (arg) in
            let (key , value) = arg
            let valueJSON = AnyJSONType(value)
            let hex = AnyJSONType(key.toString())
            features.append(H3.geojson2h3.h3ToFeature(key.toString(), ["value": valueJSON, "hex": hex]))
        }
        
        let collections = FeatureCollection(features)
        let data = try! JSONEncoder().encode(collections)
        let shape = try? MGLShape(data: data, encoding: String.Encoding.utf8.rawValue)
        let source = MGLShapeSource(identifier: sourceId, shape: shape, options: nil)
        style.addSource(source)
        
        print(String(data: data, encoding: .utf8) ?? "")
        
        features.forEach { (feature) in
            switch feature {
            case .polygonFeature(let poly):
                DispatchQueue.main.async {
                    self.renderPolygonFeature(poly, source: source, style: style, addLineLayer: addLineLayer)
                }
            default:
                print("unknown feature")
            }
        }
    }
    
    public func renderPolygonFeature(_ poly: PolygonFeature, source: MGLShapeSource, style: MGLStyle, addLineLayer: Bool) {
        let hex = poly.properties!["hex"]
        let id = hex!.jsonValue as! String
        let range = [
            1: UIColor(red: 253/255, green: 253/255, blue: 217/255, alpha: 1),
            0.5: UIColor(red: 80/255, green: 186/255, blue: 195/255, alpha: 1),
            0.25: UIColor(red: 13/255, green: 35/255, blue: 69/255, alpha: 1)
        ]
        
        let lineRange: [Double : UIColor] = [
            0.25: .white,
            0.5: .gray,
            1: .black
        ]
                        
        let hexLayer = MGLFillStyleLayer(identifier: "fill\(id)", source: source)
        hexLayer.fillColor = NSExpression(format: "mgl_step:from:stops:(value, %@, %@)", UIColor(red: 13/255, green: 35/255, blue: 69/255, alpha: 1), range)
//        hexLayer.fillOpacity = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)", [13: 20, 17: 0])
        hexLayer.fillOutlineColor = NSExpression(format: "mgl_step:from:stops:(value, %@, %@)", UIColor(red: 253/255, green: 253/255, blue: 217/255, alpha: 0.75), lineRange)
        style.addLayer(hexLayer)
        hexLayers!.append(hexLayer)
                        
////                 Create new layer for the line.
        if addLineLayer {
            let lineLayer = MGLLineStyleLayer(identifier: "polyline\(id)", source: source)

            // Set the line join and cap to a rounded end.
            lineLayer.lineJoin = NSExpression(forConstantValue: "round")
            lineLayer.lineCap = NSExpression(forConstantValue: "round")

            // Set the line color to a constant blue color.
            lineLayer.lineColor = NSExpression(forConstantValue: UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1))

            // Use `NSExpression` to smoothly adjust the line width from 2pt to 20pt between zoom levels 14 and 18. The `interpolationBase` parameter allows the values to interpolate along an exponential curve.
            lineLayer.lineWidth = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)",
            [14: 2, 18: 20])

            style.addLayer(lineLayer)
            hexLayers!.append(lineLayer)
        }
        
        hexLayers?.forEach({ (l) in l.isVisible = false })
    }
    
    func showMemoryWarning() { showWarning(title: "Memory Warning", message: "Choose higher resolution") }
}

extension ExampleViewController : LocationManagerDelegate {
    func locationManager(_ locationManager: CLLocationManager, didUpdateToLocation location: CLLocation) {
        if curLocation == nil { tableView.reloadData() }
        curLocation = location
    }
    
    func animateTo(location: CLLocation?) {
        if let center = location?.coordinate {
            let camera = MGLMapCamera(lookingAtCenter: center, altitude: 8000, pitch: 15, heading: 360)
             
                // Animate the camera movement over 5 seconds.
                mapView.setCamera(camera, withDuration: 5, animationTimingFunction: CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut))
        }
    }
}

extension ExampleViewController: MGLMapViewDelegate {
    func mapViewDidFinishLoadingMap(_ mapView: MGLMapView) {
        // Wait for the map to load before initiating the first camera movement.
         
        // Create a camera that rotates around the same center point, rotating 180°.
        // `fromDistance:` is meters above mean sea level that an eye would have to be in order to see what the map view is showing.
        animateTo(location: curLocation)
    }
    
    func mapViewRegionIsChanging(_ mapView: MGLMapView) {
        print("Zoom Level: \(mapView.zoomLevel)")
    }
    
    func mapViewDidBecomeIdle(_ mapView: MGLMapView) {
        
    }
}