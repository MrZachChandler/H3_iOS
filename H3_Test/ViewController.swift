//
//  ViewController.swift
//  H3_Test
//
//  Created by Zachary Chandler on 11/9/19.
//  Copyright © 2019 Routematch Software, Inc. All rights reserved.
//

import UIKit
import Mapbox
import CoreLocation
import SnapKit
import Turf

class ViewController: UIViewController, MGLMapViewDelegate {

    var mapView: MGLMapView?
    var curLocation: CLLocation? {
        didSet {
//            guard let loc = curLocation else { return }
//            updateLocation(loc)
        }
    }
    
    var icon: UIImage!
    var popup: UIView?
     
    enum CustomError: Error {
    case castingError(String)
    }
    
    
    ///////// child stuff
    
    var curRes: Int32 = 0
    var outer = true
    func childOfCur(location: CLLocation, res: Int32) {
        let index = H3.API.convert(toH3: location, res: res)
        let coordinates = H3.API.convertGeoCoord(from: index)
        let pointer = UnsafePointer(coordinates)
        let shape = MGLPolygon(coordinates: pointer, count: UInt(coordinates.count))
        mapView?.addAnnotation(shape)

        outer = false
        
        curRes = curRes + 1
        let neighbors = index.children(childRes: curRes)
        
//        let children = index.children(childRes: 6)
        for i in neighbors {
            let coordinates1 = H3.API.convertGeoCoord(from: i)
            let pointer1 = UnsafePointer(coordinates1)
            let shape1 = MGLPolygon(coordinates: pointer1, count: UInt(coordinates1.count))
            mapView?.addAnnotation(shape1)
        }
    }
    
    
    
    /////////
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        icon = UIImage(named: "port")

        didChange = true
        LocationManager.sharedManager.registerDelegate(self)
        addMap()
        
//        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTapCluster(sender:)))
//        doubleTap.numberOfTapsRequired = 2
//        doubleTap.delegate = self
//
//        // It's important that this new double tap fails before the map view's
//        // built-in gesture can be recognized. This is to prevent the map's gesture from
//        // overriding this new gesture (and then not detecting a cluster that had been
//        // tapped on).
//        for recognizer in mapView!.gestureRecognizers!
//        where (recognizer as? UITapGestureRecognizer)?.numberOfTapsRequired == 2 {
//        recognizer.require(toFail: doubleTap)
//        }
//        mapView!.addGestureRecognizer(doubleTap)
//
//        // Add a single tap gesture recognizer. This gesture requires the built-in
//        // MGLMapView tap gestures (such as those for zoom and annotation selection)
//        // to fail (this order differs from the double tap above).
//        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(sender:)))
//        for recognizer in mapView!.gestureRecognizers! where recognizer is UITapGestureRecognizer {
//        singleTap.require(toFail: recognizer)
//        }
//        mapView!.addGestureRecognizer(singleTap)
    }


    func addMap() {
        let url = URL(string: "mapbox://styles/mapbox/streets-v11")
        
        mapView = MGLMapView(frame: view.bounds, styleURL: url)
        mapView?.delegate = self

        // Enable heading tracking mode so that the arrow will appear.
        mapView?.userTrackingMode = .follow
         
        // Enable the permanent heading indicator, which will appear when the tracking mode is not `.followWithHeading`.
        mapView?.showsUserHeadingIndicator = true
        
        mapView?.showsUserLocation = true

        
        if let loc = curLocation {
            mapView?.setCenter(loc.coordinate, animated: true)
        }
        
        view.addSubview(mapView!)
        
        mapView?.snp.makeConstraints({ (make) in
            make.edges.equalToSuperview()
        })
    }
    
    func updateLocation(_ location: CLLocation) {
        print(location)
        DispatchQueue.main.async {
            self.mapView?.setCenter(CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude), zoomLevel: 9, animated: true)
        }
    }
    
    //9 or 10 should be smalled
    func addpolygon() {
        guard let loc = curLocation else { return }
        
        let coordinates = H3.API.generatePolygon(from: loc, res: Int32(5))
        let pointer = UnsafePointer(coordinates)
        let shape = MGLPolygon(coordinates: pointer, count: UInt(coordinates.count))
        mapView?.addAnnotation(shape)
    }
    
    var didChange = false
    var prevZoom = 3
    func addPolygon(mapView: MGLMapView) {
        guard didChange else { return }
//        guard let source = mapView.style?.source(withIdentifier: "clusteredPorts") as? MGLShapeSource else { return }
        
        let features = mapView.visibleFeatures(in: mapView.bounds, styleLayerIdentifiers: ["clusteredPorts", "ports"])
        let clusters = features.compactMap { $0 as? MGLPointFeatureCluster }

        var zoom = Int(mapView.zoomLevel - 4)
        if zoom < 3 { zoom = 3 }
        if zoom > 9 { zoom = 9 }
        
        DispatchQueue.global().async {
            // Do something heavy here, such as adding 10000 objects to an array
        
        
        guard let path = Bundle.main.path(forResource: "MARTA_Stops", ofType: "geojson") else {
                    print("parse")
                    return
                }
                
                do {
                    let fileUrl = URL(fileURLWithPath: path)
                    // Getting data from JSON file using the file URL
                    let data = try Data(contentsOf: fileUrl, options: .mappedIfSafe)
        //            json = try? JSONSerialization.jsonObject(with: data)
                    guard let geojson = try? GeoJSON.parse(FeatureCollection.self, from: data) else {
                        return
                    }
                    
                    geojson.features.forEach { (featureVariant) in
                        switch featureVariant {
                        case .pointFeature(let point):
                            let coordinate = point.geometry.coordinates
                                let loc = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                                let coordinates = H3.API.generatePolygon(from: loc, res: Int32(zoom))
                                
                                
                                let pointer = UnsafePointer(coordinates)
                                // MGLPolyline(coordinates: pointer, count: UInt(coordinates.count))
                                DispatchQueue.main.async {
                                    // Update UI here after the heavy lifting is finished, such as tableView.reloadData()
                                    let shape =  MGLPolygon(coordinates: pointer, count: UInt(coordinates.count))
                                    mapView.addAnnotation(shape)
                                }
                            
                        default:
                            print(featureVariant)
                        }
                    }
                    
                } catch {
                    // Handle error here
                }
    
        }
        // Remove any existing polyline(s) from the map.
        if zoom != prevZoom {
            if mapView.annotations?.count != nil, let existingAnnotations = mapView.annotations {
                            mapView.removeAnnotations(existingAnnotations)
                        }
        }
        
        prevZoom = zoom
//        return
        
        DispatchQueue.global().async {
            // Do something heavy here, such as adding 10000 objects to an array
        }
        
        for cluster in clusters {
//            let children = source.children(of: cluster)
//            for child in children
//            {
//            }
            
            let coordinate = cluster.coordinate
            let loc = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            let coordinates = H3.API.generatePolygon(from: loc, res: Int32(zoom))
            
            
            let pointer = UnsafePointer(coordinates)
            // MGLPolyline(coordinates: pointer, count: UInt(coordinates.count))
            DispatchQueue.main.async {
                // Update UI here after the heavy lifting is finished, such as tableView.reloadData()
                let shape =  MGLPolygon(coordinates: pointer, count: UInt(coordinates.count))
                mapView.addAnnotation(shape)
            }
        }
        
        prevZoom = zoom
        
    }
    
    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
//        addpolygon()
        return

        addPolygon(mapView: mapView)
        guard let curLocation = curLocation else {
            return
        }
        childOfCur(location: curLocation, res: curRes)
        return
        guard let path = Bundle.main.path(forResource: "MARTA_Stops", ofType: "geojson") else {
            print("parse")
            return
        }
        
        
        let url = URL(fileURLWithPath: path) 
         
        let source = MGLShapeSource(identifier: "clusteredPorts",
        url: url,
        options: [.clustered: true, .clusterRadius: icon.size.width])
        style.addSource(source)
         
        // Use a template image so that we can tint it with the `iconColor` runtime styling property.
        style.setImage(icon.withRenderingMode(.alwaysTemplate), forName: "icon")
         
        // Show unclustered features as icons. The `cluster` attribute is built into clustering-enabled
        // source features.
        let ports = MGLSymbolStyleLayer(identifier: "ports", source: source)
        ports.iconImageName = NSExpression(forConstantValue: "icon")
        ports.iconColor = NSExpression(forConstantValue: UIColor.darkGray.withAlphaComponent(0.9))
        ports.predicate = NSPredicate(format: "cluster != YES")
//        ports.iconAllowsOverlap = NSExpression(forConstantValue: true)
        style.addLayer(ports)
         
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
//        circlesLayer.circleRadius = NSExpression(forConstantValue: NSNumber(value: Double(icon.size.width) / 2))
//        circlesLayer.circleOpacity = NSExpression(forConstantValue: 0.75)
//        circlesLayer.circleStrokeColor = NSExpression(forConstantValue: UIColor.white.withAlphaComponent(0.75))
//        circlesLayer.circleStrokeWidth = NSExpression(forConstantValue: 2)
//        circlesLayer.circleColor = NSExpression(format: "mgl_step:from:stops:(point_count, %@, %@)", UIColor.lightGray, stops)
//        circlesLayer.predicate = NSPredicate(format: "cluster == YES")
        style.addLayer(circlesLayer)
         
        // Label cluster circles with a layer of text indicating feature count. The value for
        // `point_count` is an integer. In order to use that value for the
        // `MGLSymbolStyleLayer.text` property, cast it as a string.
//        let numbersLayer = MGLSymbolStyleLayer(identifier: "clusteredPortsNumbers", source: source)
//        numbersLayer.textColor = NSExpression(forConstantValue: UIColor.white)
//        numbersLayer.textFontSize = NSExpression(forConstantValue: NSNumber(value: Double(icon.size.width) / 2))
//        numbersLayer.iconAllowsOverlap = NSExpression(forConstantValue: true)
//        numbersLayer.text = NSExpression(format: "CAST(point_count, 'NSString')")
//
//        numbersLayer.predicate = NSPredicate(format: "cluster == YES")
//        style.addLayer(numbersLayer)
    }
    
    func mapView(_ mapView: MGLMapView, didSelect annotation: MGLAnnotation) {
        if let poly = annotation as? MGLPolygon {
            let loc = poly.coordinate
            if mapView.annotations?.count != nil, let existingAnnotations = mapView.annotations {
                mapView.removeAnnotations(existingAnnotations)
            }
            curRes = curRes + 1
            
            childOfCur(location: CLLocation(latitude: loc.latitude, longitude: loc.longitude), res: curRes)
            
        }
    }
     
    func mapViewRegionIsChanging(_ mapView: MGLMapView) {
        showPopup(false, animated: false)
    }
    
    func mapView(_ mapView: MGLMapView, regionDidChangeAnimated animated: Bool) {
//        didChange = true

    }
    
    func mapView(_ mapView: MGLMapView, regionIsChangingWith reason: MGLCameraChangeReason) {
         DispatchQueue.main.async {
//                   self.addPolygon(mapView: mapView)
//                   self.didChange = false
               }
    }
    
    func mapViewDidBecomeIdle(_ mapView: MGLMapView) {
    }
     
    private func firstCluster(with gestureRecognizer: UIGestureRecognizer) -> MGLPointFeatureCluster? {
        let point = gestureRecognizer.location(in: gestureRecognizer.view)
        let width = icon.size.width
        let rect = CGRect(x: point.x - width / 2, y: point.y - width / 2, width: width, height: width)
         
        // This example shows how to check if a feature is a cluster by
        // checking for that the feature is a `MGLPointFeatureCluster`. Alternatively, you could
        // also check for conformance with `MGLCluster` instead.
        let features = mapView?.visibleFeatures(in: rect, styleLayerIdentifiers: ["clusteredPorts", "ports"])
        let clusters = features?.compactMap { $0 as? MGLPointFeatureCluster }
         
        // Pick the first cluster, ideally selecting the one nearest nearest one to
        // the touch point.
        return clusters?.first
    }
     
    @objc func handleDoubleTapCluster(sender: UITapGestureRecognizer) {
     
        guard let source = mapView?.style?.source(withIdentifier: "clusteredPorts") as? MGLShapeSource else {
        return
        }
         
        guard sender.state == .ended else {
        return
        }
         
        showPopup(false, animated: false)
         
        guard let cluster = firstCluster(with: sender) else {
        return
        }
        
        let zoom = source.zoomLevel(forExpanding: cluster)
         
        if zoom > 0 {
        mapView?.setCenter(cluster.coordinate, zoomLevel: zoom, animated: true)
            }
    }
     
    @objc func handleMapTap(sender: UITapGestureRecognizer) {
     
        guard let source = mapView?.style?.source(withIdentifier: "clusteredPorts") as? MGLShapeSource else { return }
         
        guard sender.state == .ended else {
        return
        }
         
        showPopup(false, animated: false)
         
        let point = sender.location(in: sender.view)
        let width = icon.size.width
        let rect = CGRect(x: point.x - width / 2, y: point.y - width / 2, width: width, height: width)
         
        let features = mapView?.visibleFeatures(in: rect, styleLayerIdentifiers: ["clusteredPorts", "ports"])
         
        // Pick the first feature (which may be a port or a cluster), ideally selecting
        // the one nearest nearest one to the touch point.
        guard let feature = features?.first else {
        return
    }
     
        let description: String
        let color: UIColor
         
        if let cluster = feature as? MGLPointFeatureCluster {
            // Tapped on a cluster.
            let children = source.children(of: cluster)
            description = "Cluster #\(cluster.clusterIdentifier)\n\(children.count) children"
            color = .blue
        } else if let featureName = feature.attribute(forKey: "name") as? String?,
        // Tapped on a port.
            let portName = featureName {
            description = portName
            color = .black
        } else {
            // Tapped on a port that is missing a name.
            description = "No port name"
            color = .red
        }
         
        popup = popup(at: feature.coordinate, with: description, textColor: color)
         
        showPopup(true, animated: true)
    }
     
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
        guard let point = mapView?.convert(coordinate, toPointTo: mapView) else { return UIView() }
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
     
    extension ViewController: UIGestureRecognizerDelegate {
     
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    // This will only get called for the custom double tap gesture,
    // that should always be recognized simultaneously.
    return true
    }
     
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    // This will only get called for the custom double tap gesture.
    return firstCluster(with: gestureRecognizer) != nil
    }
    }

extension ViewController : LocationManagerDelegate {
    func locationManager(_ locationManager: CLLocationManager, didUpdateToLocation location: CLLocation) {
        curLocation = location
//        updateLocation(location)
    }
        
    func mapView(_ mapView: MGLMapView, alphaForShapeAnnotation annotation: MGLShape) -> CGFloat {
        if outer { return 0.1 }
        return 0.3
    }
    
    func mapView(_ mapView: MGLMapView, strokeColorForShapeAnnotation annotation: MGLShape) -> UIColor {
        return .black
    }
     
    func mapView(_ mapView: MGLMapView, fillColorForPolygonAnnotation annotation: MGLPolygon) -> UIColor {
        return .blue
    }
    
    
    
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
    // This example is only concerned with point annotations.
    guard annotation is MGLPointAnnotation else {
    return nil
    }
     
    // Use the point annotation’s longitude value (as a string) as the reuse identifier for its view.
    let reuseIdentifier = "\(annotation.coordinate.longitude)"
     
    // For better performance, always try to reuse existing annotations.
    var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)
     
    // If there’s no reusable annotation view available, initialize a new one.
    if annotationView == nil {
    annotationView = CustomAnnotationView(reuseIdentifier: reuseIdentifier)
    annotationView!.bounds = CGRect(x: 0, y: 0, width: 40, height: 40)
     
    // Set the annotation view’s background color to a value determined by its longitude.
    let hue = CGFloat(annotation.coordinate.longitude) / 100
    annotationView!.backgroundColor = UIColor(hue: hue, saturation: 0.5, brightness: 1, alpha: 1)
    }
     
    return annotationView
    }
     
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
    return true
    }
     
}
//
//extension ViewController: MGLMapViewDelegate {
//    func mapViewDidFinishLoadingMap(_ mapView: MGLMapView) {
//    // Wait for the map to load before initiating the first camera movement.
//
//    // Create a camera that rotates around the same center point, rotating 180°.
//    // `fromDistance:` is meters above mean sea level that an eye would have to be in order to see what the map view is showing.
//
//        guard let cur = curLocation else { return }
//
//        let camera = MGLMapCamera(lookingAtCenter: cur.coordinate, altitude: 4500, pitch: 15, heading: 180)
//
//    // Animate the camera movement over 5 seconds.
//    mapView.setCamera(camera, withDuration: 5, animationTimingFunction: CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut))
//    }
//}
//
// MGLAnnotationView subclass
class CustomAnnotationView: MGLAnnotationView {
override func layoutSubviews() {
super.layoutSubviews()
 
// Use CALayer’s corner radius to turn this view into a circle.
layer.cornerRadius = bounds.width / 2
layer.borderWidth = 2
layer.borderColor = UIColor.white.cgColor
}
 
override func setSelected(_ selected: Bool, animated: Bool) {
super.setSelected(selected, animated: animated)
 
// Animate the border width in/out, creating an iris effect.
let animation = CABasicAnimation(keyPath: "borderWidth")
animation.duration = 0.1
layer.borderWidth = selected ? bounds.width / 4 : 2
layer.add(animation, forKey: "borderWidth")
}
}



