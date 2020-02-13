//
//  ClusterViewController.swift
//  H3_Test
//
//  Created by Zachary Chandler on 2/7/20.
//  Copyright © 2020 Zachary Chandler All rights reserved.
//

import Foundation
import UIKit
import Mapbox
import H3Swift
import Turf
import Eureka

class PointLayerViewController: ExampleViewController {
    override var resolution: Int32 {
        didSet {
            resDidChange = true
            removeAll()
        }
    }
    var resDidChange = false
    typealias PointsLayer = (Bool, Bool, Bool)
    var countPointsLayer: [MGLStyleLayer] = []
    var bufferPointsLayer: [MGLStyleLayer] = []
    var bufferLinearLayer: [MGLStyleLayer] = []
    var sources = ["count", "buffer", "linear", "hex_linear"]
    
    func removeAll() {
        var layers: [MGLStyleLayer] = []
        layers.append(contentsOf: countPointsLayer)
        layers.append(contentsOf: bufferPointsLayer)
        layers.append(contentsOf: bufferLinearLayer)

        if let hex = hexLayers {
            layers.append(contentsOf: hex)
        }
        
        layers.forEach { (layer) in
            mapView.style?.removeLayer(layer)
        }
        
        for id in sources {
            if let source = mapView.style?.source(withIdentifier: id) {
                mapView.style?.removeSource(source)
                print("removed source with ID: \(id)")
            }
        }
        
        bufferLinearLayer.removeAll()
        countPointsLayer.removeAll()
        bufferPointsLayer.removeAll()
    }
    
    func hideHexagons() {
        hexLayers?.forEach({ (layer) in
            layer.isVisible = false
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTapGestures()
        
        form +++ Section("Raw Point Data")
            
            <<< StepperRow("Res") {
                $0.title = "Res"
                $0.value = Double(resolution)
                $0.cellUpdate { [unowned self] (cell, row) in
                    guard let v = row.value else { return }
                    self.resolution = Int32(v)
                }
            }
            
            <<< SwitchRow("hubs") {
                $0.title = "Show Hubs"
                $0.value = false
                $0.onChange {[unowned self]  (row) in
                    guard let cluster = row.value else { return }
                    self.clusterLayer?.forEach({ (layer) in layer.isVisible = false })
                    self.hubsLayer?.isVisible = cluster
                    self.hideHexagons()
                }
            }
                
            +++ Section(footer: "This groups hubs together")
                
            <<< SwitchRow("cluster") {
                $0.title = "Cluster Hubs"
                $0.value = false
                $0.onChange {[unowned self]  (row) in
                    guard let cluster = row.value else { return }
                    self.clusterLayer?.forEach({ (layer) in layer.isVisible = cluster })
                    self.hideHexagons()
                }
            }
                
            +++ Section("Hexagon Transformation")
                
            <<< SwitchRow("count") {
                $0.title = "countPoints"
                $0.value = false
                $0.onChange { [unowned self] (row) in
                    guard let show = row.value else { return }
                    self.addLayer(for: (show,false,false))
                }
            }
        
            <<< SwitchRow("buffer") {
                $0.title = "buffer"
                $0.value = false
                $0.onChange {[unowned self]  (row) in
                    guard let show = row.value else { return }
                    self.addLayer(for: (false,show,false))
                }
            }
                
            <<< SwitchRow("bufferLinear") {
                $0.title = "bufferLinear"
                $0.value = false
                $0.onChange {[unowned self]  (row) in
                    guard let show = row.value else { return }
                    self.addLayer(for: (false,false,show))
                }
            }
            
            tableView.reloadData()
    }
    
    func renderPolygonFeature(for point: PointsLayer, poly: PolygonFeature, source: MGLShapeSource, style: MGLStyle, addLineLayer: Bool) {
            let hex = poly.properties!["hex"]
            let id = hex!.jsonValue as! String
            let range: [Double: UIColor] = [ 0: #colorLiteral(red: 0.9979701638, green: 0.9997151494, blue: 0.8536984324, alpha: 1), 0.5: #colorLiteral(red: 0.3144622147, green: 0.728943646, blue: 0.7659309506, alpha: 1), 1: #colorLiteral(red: 0.1020374969, green: 0.2753289044, blue: 0.5405613184, alpha: 1) ]
            let hexLayer = MGLFillStyleLayer(identifier: "fill\(id)\(source.identifier)", source: source)
            hexLayer.fillColor = NSExpression(format: "mgl_step:from:stops:(value, %@, %@)", UIColor(red: 13/255, green: 35/255, blue: 69/255, alpha: 1), range)
            hexLayer.fillOpacity = NSExpression(forConstantValue: 0.75)
            style.addLayer(hexLayer)
            hexLayers!.append(hexLayer)
            
            if point.0 { countPointsLayer.append(hexLayer) }
            if point.1 { bufferPointsLayer.append(hexLayer) }
            if point.2 { bufferLinearLayer.append(hexLayer) }
                            
    ////                 Create new layer for the line.
            if addLineLayer {
                let lineLayer = MGLLineStyleLayer(identifier: "polyline\(id)\(source.identifier)", source: source)

                // Set the line join and cap to a rounded end.
                lineLayer.lineJoin = NSExpression(forConstantValue: "round")
                lineLayer.lineCap = NSExpression(forConstantValue: "round")

                // Set the line color to a constant color contrast for style.
                lineLayer.lineColor = NSExpression(forConstantValue: Style.shared.preference.textColor)

                // Use `NSExpression` to smoothly adjust the line width from 2pt to 20pt between zoom levels 14 and 18. The `interpolationBase` parameter allows the values to interpolate along an exponential curve.
                lineLayer.lineWidth = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)",
                [6: 2, 18: 0])

                style.addLayer(lineLayer)
                hexLayers!.append(lineLayer)
                
                if point.0 { countPointsLayer.append(lineLayer) }
                if point.1 { bufferPointsLayer.append(lineLayer) }
                if point.2 { bufferLinearLayer.append(lineLayer) }
            }
            
            hexLayers?.forEach({ (l) in l.isVisible = true })
        }
    
    func renderHexagons(for points: PointsLayer, layer :  [H3Index : Double], style: MGLStyle, sourceId: String = "hex_linear", addLineLayer: Bool = false) {
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
                    self.renderPolygonFeature(for: points, poly: poly, source: source, style: style, addLineLayer: addLineLayer)
                    self.stopLoading()
                }
            default:
                print("unknown feature")
            }
        }
    }
    
    func addClusterData(_ mapView: MGLMapView, didFinishLoading style: MGLStyle)  {
            guard self.clusterLayer == nil else { return }
            self.clusterLayer = []
            
            let url = URL(fileURLWithPath: Bundle.main.path(forResource: "MARTA_Stops", ofType: "geojson")!)
            
            let source = MGLShapeSource(identifier: "clusteredHubs",
            url: url,
            options: [.clustered: true, .clusterRadius: self.icon.size.width])
            style.addSource(source)
                     
            // Use a template image so that we can tint it with the `iconColor` runtime styling property.
            style.setImage(self.icon.withRenderingMode(.alwaysTemplate), forName: "icon")
             
            // Show unclustered features as icons. The `cluster` attribute is built into clustering-enabled
            // source features.
            let hubs = MGLSymbolStyleLayer(identifier: "hubs", source: source)
            hubs.iconImageName = NSExpression(forConstantValue: "icon")
            hubs.iconColor = NSExpression(forConstantValue: UIColor.orange)
            hubs.predicate = NSPredicate(format: "cluster != YES")
            hubs.iconAllowsOverlap = NSExpression(forConstantValue: true)
            style.addLayer(hubs)
             
            self.clusterLayer?.append(hubs)

            // Color clustered features based on clustered point counts.
            let stops = [
                20: UIColor.lightGray,
                50: UIColor.orange,
                100: UIColor.red,
                200: UIColor.purple
            ]
             
            // Show clustered features as circles. The `point_count` attribute is built into
            // clustering-enabled source features.
            let circlesLayer = MGLCircleStyleLayer(identifier: "clusteredPorts", source: source)
            circlesLayer.circleRadius = NSExpression(forConstantValue: NSNumber(value: Double(self.icon.size.width) / 2))
            circlesLayer.circleOpacity = NSExpression(forConstantValue: 0.75)
            circlesLayer.circleStrokeColor = NSExpression(forConstantValue: UIColor.white.withAlphaComponent(0.75))
            circlesLayer.circleStrokeWidth = NSExpression(forConstantValue: 2)
            circlesLayer.circleColor = NSExpression(format: "mgl_step:from:stops:(point_count, %@, %@)", UIColor.lightGray, stops)
            circlesLayer.predicate = NSPredicate(format: "cluster == YES")
            style.addLayer(circlesLayer)
             
            self.clusterLayer?.append(circlesLayer)
            
            // Label cluster circles with a layer of text indicating feature count. The value for
            // `point_count` is an integer. In order to use that value for the
            // `MGLSymbolStyleLayer.text` property, cast it as a string.
            let numbersLayer = MGLSymbolStyleLayer(identifier: "clusteredPortsNumbers", source: source)
            numbersLayer.textColor = NSExpression(forConstantValue: UIColor.white)
            numbersLayer.textFontSize = NSExpression(forConstantValue: NSNumber(value: Double(self.icon.size.width) / 2))
            numbersLayer.iconAllowsOverlap = NSExpression(forConstantValue: true)
            numbersLayer.text = NSExpression(format: "CAST(point_count, 'NSString')")
             
            numbersLayer.predicate = NSPredicate(format: "cluster == YES")
            style.addLayer(numbersLayer)
            self.clusterLayer?.append(numbersLayer)
            
            
            // Use a template image so that we can tint it with the `iconColor` runtime styling property.
            style.setImage(UIImage(named: "hub")!.withRenderingMode(.alwaysTemplate), forName: "hublife")
            
            let source2 = MGLShapeSource(identifier: "unclust", url: url, options: nil)
            let hubsLayer = MGLSymbolStyleLayer(identifier: "hubs_unclustered", source: source2)
            hubsLayer.iconImageName = NSExpression(forConstantValue: "hublife")
            hubsLayer.iconColor = NSExpression(forConstantValue: UIColor.orange)
            hubsLayer.iconAllowsOverlap = NSExpression(forConstantValue: true)
            style.addSource(source2)
            style.addLayer(hubsLayer)
            
            self.hubsLayer = hubsLayer
            
            self.clusterLayer?.forEach({ layer in layer.isVisible = false })
            self.hubsLayer?.isVisible = false
//        })
    }
         
    func firstCluster(with gestureRecognizer: UIGestureRecognizer) -> MGLPointFeatureCluster? {
        let point = gestureRecognizer.location(in: gestureRecognizer.view)
        let width = icon.size.width
        let rect = CGRect(x: point.x - width / 2, y: point.y - width / 2, width: width, height: width)
            
        // This example shows how to check if a feature is a cluster by
        // checking for that the feature is a `MGLPointFeatureCluster`. Alternatively, you could
        // also check for conformance with `MGLCluster` instead.
        let features = mapView.visibleFeatures(in: rect, styleLayerIdentifiers: ["clusteredHubs", "hubs"])
        let clusters = features.compactMap { $0 as? MGLPointFeatureCluster }
             
        // Pick the first cluster, ideally selecting the one nearest nearest one to
        // the touch point.
        return clusters.first
    }
}
/// - NOTE: MAP FUNCTIONS
extension PointLayerViewController {
    
    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        addClusterData(mapView, didFinishLoading: style)
    }
    
    func addLayer(for points: PointsLayer) {
        hideHexagons()
        guard points.1 || points.0 || points.2 else { return }
        guard let style = mapView.style else { return }
        
        if points.0 && countPointsLayer.count > 0 {
            if resDidChange {
                countPointsLayer.forEach { (layer) in
                    mapView.style?.removeLayer(layer)
                }
                countPointsLayer.removeAll()
                //remove source
            }
            else {
                countPointsLayer.forEach{$0.isVisible = true}
                return
            }
        }
        if points.1 && bufferPointsLayer.count > 0 {
            if resDidChange {
                bufferPointsLayer.forEach { (layer) in
                    mapView.style?.removeLayer(layer)
                }
                bufferPointsLayer.removeAll()
                //remove source
            }
            else {
                bufferPointsLayer.forEach{$0.isVisible = true}
                return
            }
        }
        if points.2 && bufferLinearLayer.count > 0 {
            if resDidChange {
                bufferLinearLayer.forEach { (layer) in
                    mapView.style?.removeLayer(layer)
                }
                bufferLinearLayer.removeAll()
                //remove source
            }
            else {
                bufferLinearLayer.forEach{$0.isVisible = true}
                return
            }
        }
        
        startLoading()
        
         DispatchQueue.global(qos: .background).async(execute: {
            let url = URL(fileURLWithPath: Bundle.main.path(forResource: "MARTA_Stops", ofType: "geojson")!)

            if let jsonData = try? Data(contentsOf: url, options: .mappedIfSafe)
            {
                let decoder = JSONDecoder()
                if let feature = try? decoder.decode(FeatureCollection.self, from: jsonData) {
                    DispatchQueue.main.async {
                        if points.0 {
                            self.renderHexagons(for: points, layer: self.countPoints(feature), style: style, sourceId: "count", addLineLayer: true)
                        }
                        if points.1 {
                            self.renderHexagons(for: points, layer: self.bufferPoints(feature, radius: 2), style: style, sourceId: "buffer", addLineLayer: true)
                        }
                        if points.2 {
                            self.renderHexagons(for: points, layer: self.bufferPointsLinear(feature, radius: 2), style: style, sourceId: "linear", addLineLayer: true)
                        }
                    }
                 }
             }
        })
    }

    override func mapViewRegionIsChanging(_ mapView: MGLMapView) {
       showPopup(false, animated: false)
    }
}
/// - NOTE: TAP GESTURE EXTENSION
extension PointLayerViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
       // This will only get called for the custom double tap gesture,
       // that should always be recognized simultaneously.
       return true
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
       // This will only get called for the custom double tap gesture.
       return firstCluster(with: gestureRecognizer) != nil
    }
    
    func setupTapGestures() {
        // Add a double tap gesture recognizer. This gesture is used for double
        // tapping on clusters and then zooming in so the cluster expands to its
        // children.
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTapCluster(sender:)))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
         
        // It's important that this new double tap fails before the map view's
        // built-in gesture can be recognized. This is to prevent the map's gesture from
        // overriding this new gesture (and then not detecting a cluster that had been
        // tapped on).
        for recognizer in mapView.gestureRecognizers!
        where (recognizer as? UITapGestureRecognizer)?.numberOfTapsRequired == 2 {
            recognizer.require(toFail: doubleTap)
        }
        
        mapView.addGestureRecognizer(doubleTap)
         
        // Add a single tap gesture recognizer. This gesture requires the built-in
        // MGLMapView tap gestures (such as those for zoom and annotation selection)
        // to fail (this order differs from the double tap above).
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(sender:)))
        for recognizer in mapView.gestureRecognizers! where recognizer is UITapGestureRecognizer {
            singleTap.require(toFail: recognizer)
        }
        
        mapView.addGestureRecognizer(singleTap)
        
    }
    
    @objc func handleDoubleTapCluster(sender: UITapGestureRecognizer) {
        guard let source = mapView.style?.source(withIdentifier: "clusteredHubs") as? MGLShapeSource ?? mapView.style?.source(withIdentifier: "unclust") as? MGLShapeSource else { return }
        guard sender.state == .ended else { return }
            
        showPopup(false, animated: false)
            
        guard let cluster = firstCluster(with: sender) else { return }
        
        let zoom = source.zoomLevel(forExpanding: cluster)
            
        if zoom > 0 {
            mapView.setCenter(cluster.coordinate, zoomLevel: zoom, animated: true)
        }
    }
    
    @objc func handleMapTap(sender: UITapGestureRecognizer) {
        guard let source = mapView.style?.source(withIdentifier: "clusteredHubs") as? MGLShapeSource ?? mapView.style?.source(withIdentifier: "unclust") as? MGLShapeSource else { return }
        guard sender.state == .ended else { return }
     
        showPopup(false, animated: false)
         
        let point = sender.location(in: sender.view)
        let width = icon.size.width
        let rect = CGRect(x: point.x - width / 2, y: point.y - width / 2, width: width, height: width)
         
        let features = mapView.visibleFeatures(in: rect, styleLayerIdentifiers: ["clusteredHubs", "hubs"])
        let unclustered = mapView.visibleFeatures(in: rect, styleLayerIdentifiers: ["unclust", "hubs_unclustered"])
         
        // Pick the first feature (which may be a port or a cluster), ideally selecting
        // the one nearest nearest one to the touch point.
        guard let feature = features.first ?? unclustered.first else { return }
     
        let description: String
        let color: UIColor
         
        if let cluster = feature as? MGLPointFeatureCluster {
            // Tapped on a cluster.
            let children = source.children(of: cluster)
            description = "Cluster #\(cluster.clusterIdentifier)\n\(children.count) children"
            color = .blue
        } else if let featureName = feature.attribute(forKey: "stop_name") as? String?,
            // Tapped on a port.
            let portName = featureName {
                description = portName
                color = .black
        } else {
            // Tapped on a port that is missing a name.
            description = "No Hub name"
            color = .red
        }
     
        popup = popup(at: feature.coordinate, with: description, textColor: color)
        showPopup(true, animated: true)
    }
}
/// - NOTE: POPUP EXTENSION
extension PointLayerViewController {
    // Convenience method to create a reusable popup view.
    func popup(at coordinate: CLLocationCoordinate2D, with description: String, textColor: UIColor) -> UIView {
        let popup = UILabel()
         
        popup.backgroundColor     = UIColor.white.withAlphaComponent(0.9)
        popup.layer.cornerRadius  = 4
        popup.layer.masksToBounds = true
        popup.textAlignment       = .center
        popup.lineBreakMode       = .byTruncatingTail
        popup.numberOfLines       = 0
        popup.font                = .systemFont(ofSize: 16)
        popup.textColor           = textColor
        popup.alpha               = 0
        popup.text                = description
         
        popup.sizeToFit()
         
        // Expand the popup.
        popup.bounds = popup.bounds.insetBy(dx: -10, dy: -10)
        guard let point = mapView?.convert(coordinate, toPointTo: view) else { return UIView() }
        popup.center = CGPoint(x: point.x, y: point.y - 50)
         
        return popup
    }
    
    func showPopup(_ shouldShow: Bool, animated: Bool) {
        guard let popup = self.popup else {
            return
        }
         
        if shouldShow {
            view.addSubview(popup)
        }
         
        let alpha: CGFloat = (shouldShow ? 1 : 0)
         
        let animation = {
            popup.alpha = alpha
        }
         
        let completion = { (_: Bool) in
            if !shouldShow {
                popup.removeFromSuperview()
            }
        }
         
        if animated {
            UIView.animate(withDuration: 0.25, animations: animation, completion: completion)
        } else {
            animation()
            completion(true)
        }
    }
}

extension Double {
    func normalize(min: Double, max: Double, from a: Double = 0, to b: Double = 1) -> Double {
        return (b - a) * ((self - min) / (max - min)) + a
    }
}
