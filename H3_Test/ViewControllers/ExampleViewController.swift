//
//  ExampleViewController.swift
//  H3_Test
//
//  Created by Zachary Chandler on 1/26/20.
//  Copyright © 2020 Zachary Chandler All rights reserved.
//

import Foundation
import Mapbox
import SnapKit
import Eureka
import Turf
import H3Swift

class ExampleViewController: FormViewController, H3MapDelegate {
    var example: Example! { didSet { title = example.title }}
    var hexLayers: [MGLStyleLayer] = []
    var resolution: Int32 = 7
    var mapView: MGLMapView!
    var activity: UIActivityIndicatorView?
    var actView: UIView?
    var isLoading = false
    // normalize from minMax.0 -> minMax.1
    var minMax: MinMax = (10000000.0, -1.0)
    var curLocation: CLLocation { return CLLocation(latitude: 33.789, longitude: -84.384) }

    var hexColorRange: ColorRange!
    override var shouldAutorotate: Bool { return true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { return .landscape }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hexColorRange = userInterfaceStyle.shortRange
        mapView = MGLMapView(frame: view.bounds)
        mapView.delegate = self
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.showsUserHeadingIndicator = true
        mapView.styleURL = userInterfaceStyle.mapStyle
        
        view.addSubview(mapView)
        
        form +++ Section("Resolution") {
                $0.footer = HeaderFooterView(title: self.example.title)
            }
            
            <<< StepperRow("Res") {
                $0.title = "Res"
                $0.value = Double(resolution)
                $0.cellUpdate { [unowned self] (cell, row) in
                    guard let v = row.value else { return }
                    self.resolution = Int32(v)
                }
            }
            
            <<< ButtonRow("apply") {
                $0.title = "Apply"
            }
            .onCellSelection({ [unowned self] (_, _) in
                self.addHexagons { [weak self] in self?.stopLoading() }
            })
        
            tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        addHexagons {
            [weak self] in
            self?.stopLoading()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        mapView.snp.makeConstraints { make in
            make.top.bottom.right.equalToSuperview()
            make.width.equalTo(view.frame.width - (view.frame.width / 3))
        }
        
        tableView.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.right.equalTo(mapView.snp.left)
        }
    }
    
    func addHexagons(_ completion: @escaping () -> Void) {
        
    }
    
    func addHexagonData(toStyle style: MGLStyle, forSourceID sourceId: String, withValueKey key: String, forResource resource: String, ofType type: String, completion block: @escaping () -> Void) {
       startLoading()

       // parsing geojson takes a while so lets do it in the background
       DispatchQueue.global(qos: .background).async(execute: { [weak self] in
           defer { DispatchQueue.main.async { block() } }
           
           guard let featureCollection = self?.getlocalData(forResource: resource, ofType: type) else { return }
           guard let data = self?.createHexLayer(featureCollection: featureCollection, valueKey: key) else { return }
           guard let shape = try? MGLShape(data: data, encoding: String.Encoding.utf8.rawValue) else { return }
           guard let source = style.source(withIdentifier: sourceId) as? MGLShapeSource else {
               self?.createSource(style: style, shape: shape, sourceId: sourceId)
               return
           }
           
           DispatchQueue.main.async { source.shape = shape }
       })
    }
       
   
    func getlocalData(forResource resource: String, ofType type: String ) -> FeatureCollection? {
        guard let path = Bundle.main.path(forResource: resource, ofType: type) else { return nil }
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe) else { return nil }
        return try? JSONDecoder().decode(FeatureCollection.self, from: data)
    }
       
    func createHexLayer(featureCollection: FeatureCollection, valueKey key: String) -> Data? {
       // We create a hexagon layer
       var layers: [H3Index: Double] = [:]
       // find min max value for
       var min = 1000000.0
       var max = 0.0
       
       for feature in featureCollection.features {
           guard let poly = feature.value as? PolygonFeature else { continue }
           let value = poly.properties?[key]?.jsonValue
           if let stringValue = value as? String, let d = Double(stringValue) {
               if d < min { min = d }
               if d > max { max = d }
           }
       }
       
       for feature in featureCollection.features {
           guard let hexagons = H3.geojson2h3.featureToH3Set(feature, resolution)?.h3Indexs else { continue }
           guard let poly = feature.value as? PolygonFeature, let v = poly.properties?[key]?.jsonValue as? String, let value = Double(v) else { continue }
           
           hexagons.forEach{layers[$0] = value.normalize(min: min, max: max, from: minMax.0, to: minMax.1)}
       }
       
       // Turn the feature collection back into
       var features : [FeatureVariant] = []
       layers.forEach { (key , value) in
           var valueJSON = AnyJSONType(value.jsonValue)
           if value.isNaN { valueJSON = AnyJSONType(0) }
           features.append(H3.geojson2h3.h3ToFeature(key.toString(), ["value": valueJSON]))
       }
       
        let collection = FeatureCollection(features)
       return try? JSONEncoder().encode(collection)
    }
   
    func createSource(style: MGLStyle, shape: MGLShape, sourceId id: String) {
       DispatchQueue.main.async { [weak self] in
           guard let self = self else { return }
           
           let source = MGLShapeSource(identifier: id, shape: shape, options: nil)
           let hexLayer = MGLFillStyleLayer(identifier: id, source: source)
           hexLayer.fillColor = NSExpression(format: "mgl_step:from:stops:(value, %@, %@)", #colorLiteral(red: 0.004857238848, green: 0, blue: 0.1536510587, alpha: 1), self.hexColorRange)
           hexLayer.fillOpacity = NSExpression(forConstantValue: 0.75)
           hexLayer.fillOutlineColor = NSExpression(forConstantValue: self.userInterfaceStyle.textColor)

           style.addLayer(hexLayer)
           style.addSource(source)
           self.hexLayers.append(hexLayer)
       }
    }
    
    func layerToFeatureCollection(layer :  [H3Index : Double] , valueKey: String) -> FeatureCollection {
        var features : [FeatureVariant] = []
        
        layer.forEach { (key , value) in
            let valueJSON = AnyJSONType("\(value)")
            let hex = AnyJSONType(key.toString())
            let properties = [valueKey: valueJSON, "hex": hex]
            features.append(H3.geojson2h3.h3ToFeature(key.toString(), properties))
        }
        
        let collection = FeatureCollection(features)
        return collection
    }
    
       func startLoading() {
            guard activity == nil else { return }
        
            let activity = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
            activity.color = userInterfaceStyle.backgroundColor
            let actView = UIView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
            actView.backgroundColor = userInterfaceStyle.activityViewColor
            actView.alpha = 0
            actView.layer.cornerRadius = 10
            actView.addSubview(activity)
            
            view.addSubview(actView)
            view.bringSubviewToFront(actView)
            
            activity.snp.makeConstraints {
                $0.center.equalTo(actView.snp.center).inset(32)
            }
            
            actView.snp.makeConstraints {
                $0.center.equalTo(mapView.snp.center)
                $0.height.equalTo(60)
                $0.width.equalTo(60)
            }
            
            UIView.animate(withDuration: 2) { actView.alpha = 0.75 }
            
            self.activity = activity
            self.actView = actView
            
            activity.startAnimating()
        }
        
        func stopLoading() {
            UIView.animate(withDuration: 2) { [weak self] in self?.actView?.alpha = 0 }
            
            isLoading = false
            
            activity?.stopAnimating()
            activity?.removeFromSuperview()
            activity = nil
            
            actView?.removeFromSuperview()
            actView = nil
        }
}

extension ExampleViewController: MGLMapViewDelegate {
    
    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        // Wait for the style to load before adding data layers
        addHexagons { [weak self] in self?.stopLoading() }
    }
    
    func mapViewDidFinishLoadingMap(_ mapView: MGLMapView) {
        // Wait for the map to load before initiating the first camera movement.
        animateTo(location: curLocation)
    }
    
    func mapViewRegionIsChanging(_ mapView: MGLMapView) {
        print("Zoom Level: \(mapView.zoomLevel)")
    }
    
    func mapViewDidBecomeIdle(_ mapView: MGLMapView) {
        print("mapViewDidBecomeIdle - Zoom Level: \(mapView.zoomLevel)")
    }
}

extension ExampleViewController {
 
    
    func resolutionFor(zoom: Double) -> Int32 {
        print("Zoom Level: \(zoom)")
        
        if zoom > 0 && zoom < 1.853063744141729 {
            return 0
        }
        
        if zoom > 1.853063744141729 && zoom < 3.588471291512631 {
             return 1
        }
        
        if zoom > 3.788471291512631 && zoom < 4.903808231973731 {
            return 2
        }
        
        if zoom > 4.903808231973731 && zoom < 5.913376266724374 {
            return 3
        }

        if zoom > 5.913376266724374 && zoom < 7.410816641816707 {
            return 4
        }
        
        if zoom > 7.410816641816707 && zoom < 8.62971294362284 {
            return 5
        }
        
        if zoom > 8.62971294362284 && zoom < 9.829072097381182 {
            return 6
        }

        if zoom > 9.829072097381182 && zoom < 11.507805940301576 {
            return 7
        }
        
        if zoom > 11.507805940301576 && zoom < 12.888188650293314 {
            return 8
        }
        
        if zoom > 12.888188650293314 && zoom < 14.40879478604411 {
            return 9
        }
        
        if zoom > 14.40879478604411 && zoom < 15.734850005189664 {
            return 10
        }
        
        return 11
    }
}
