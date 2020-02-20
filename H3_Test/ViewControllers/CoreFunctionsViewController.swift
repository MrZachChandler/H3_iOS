//
//  CoreFunctionsViewController.swift
//  H3_Test
//
//  Created by Zachary Chandler on 1/26/20.
//  Copyright © 2020 Zachary Chandler All rights reserved.
//

import Eureka
import Mapbox
import Turf
import H3Swift

class CoreFunctionsViewController: ExampleViewController {
    var points:[CLLocationCoordinate2D] = []
    var originalMarker: MGLPointAnnotation!
    var lossMarker: MGLPointAnnotation!
    var numberOfRings: Int32 = 0
    var polyonFeature: PolygonFeature?
    var sources = ["single_hex"]
    var polygonIDs: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let c = CLLocationCoordinate2D(latitude: 33.789, longitude: -84.384)
        let marker = MGLPointAnnotation()
        marker.coordinate = c
        
        originalMarker = marker
        resolution = 0
        points.append(c)
        mapView.showsUserLocation = false
        mapView.addAnnotation(marker)

        form +++ Section("Core Functions") {
                $0.footer = HeaderFooterView(title: "Lossy Data!")
            }
            
            <<< StepperRow("Res") {
                $0.title = "Res"
                $0.value = Double(resolution)
                $0.cellUpdate { [unowned self] (cell, row) in
                    guard let v = row.value else { return }
                    self.resolution = Int32(v)
                }
            }

            <<< SwitchRow("geotoH3") {
                $0.title = "geotoH3"
                $0.value = false
                $0.onChange { [unowned self]  (row) in
                    guard let v = row.value else { return }
                    self.convertAndShowHex(v)
                }
            }
            <<< SwitchRow("chilrenCell")  {
                $0.title = "Show Children"
                $0.value = false
                $0.hidden = Condition.function(["geotoH3"], { form in
                    return !((form.rowBy(tag: "geotoH3") as? SwitchRow)?.value ?? false)
                })
                $0.onChange { [unowned self]  (row) in
                    guard let v = row.value else { return }
                    self.showChildren(v)
                }
            }
                        
            <<< SwitchRow("h3ToGeo") {
                $0.title = "h3ToGeo"
                $0.value = false
                $0.onChange {[unowned self]  (row) in
                    guard let v = row.value else { return }
                    self.refreshLossyMarker(v)
                }
            }
                
            +++ Section("Polygon Layer")
                
            <<< SwitchRow("Show Hexagons") {
                $0.title = "Fill"
                $0.value = false
                $0.onChange { [unowned self]  (row) in
                    guard let show = row.value else { return }
                    if show {
                        self.polyfillMap()
                    } else {
                        self.removeAllLayers()
                        self.removeAllSources()
                    }
                }
            }
        
            <<< SwitchRow("MultiPolygon") {
                $0.title = "Multipolygon"
                $0.value = false
                $0.onChange {[unowned self]  (row) in
                    guard let show = row.value else { return }
                    if show {
                        self.multiPolyfillMap()
                    } else {
                        self.removeAllLayers()
                        self.removeAllSources()
                    }
                }
            }
            
            +++ Section("Rings")
            <<< StepperRow("Rings") {
                $0.title = "#"
                $0.value = 1
                $0.cellUpdate {[unowned self]  (cell, row) in
                    guard let v = row.value else { return }
                    self.numberOfRings = Int32(v)
                }
            }
            
            <<< SwitchRow("kRings") {
                $0.title = "kRings"
                $0.value = false
                $0.onChange {[unowned self]  (row) in
                    guard let show = row.value else { return }
                    self.kRings(show: show)
                }
            }
            
            <<< SwitchRow("hexRings") {
                $0.title = "hexRing "
                $0.value = false
                $0.onChange {[unowned self]  (row) in
                    guard let show = row.value else { return }
                    self.hexRings(show: show)
                }
            }
        
        tableView.reloadData()
    }
    
    func showChildren(_ show: Bool) {
        guard show else {
            removeAllLayers()
            removeAllSources()
            
            return
        }
        
        guard let style = mapView.style else { return }
        // create reference
        var geoCoord = originalMarker.coordinate.geoCoord
        // create indeex
        let index = geoCoord.toH3(res: resolution)
        // create dictionary
        var layer : [H3Index:Double] = [:]
        // create children
        let res = resolution == 15 ? resolution : resolution + 1
        res == resolution ? resolutionError() : index.children(childRes: res).forEach { layer[$0] = 1 }
        //render hexagons
        renderHexer(layer: layer, style: style, addLineLayer: true)
    }
    
    func resolutionError() { showWarning(title: "Resolution Error", message: "Choose another resolution") }
    
    func kRings(show: Bool) {
         if show {
             guard let style = mapView.style else { return }
             
             var geoChord = originalMarker.coordinate.geoCoord
             let index = geoChord.toH3(res: resolution)
             let rings = index.kRing(k: numberOfRings)
             var layer : [H3Index : Double] = [index:0]
             rings.forEach { layer[$0] = 1.0 }
             renderHexer(layer: layer, style: style, addLineLayer: true)
         }
         else {
             removeAllLayers()
             removeAllSources()
         }
     }
    
    func hexRings(show: Bool) {
        if show {
            guard let style = mapView.style else { return }
            
            var layer : [H3Index : Double] = [:]
            var geoChord = originalMarker.coordinate.geoCoord
            
            let index = geoChord.toH3(res: resolution)
            let rings = index.kRingDistances(k: numberOfRings)
            let ringIndex = Int(numberOfRings)
            let hexRing = rings[ringIndex]
            
            hexRing.forEach { layer[$0] = 1.0 }
            renderHexer(layer: layer, style: style, addLineLayer: true)
        }
        else {
            removeAllLayers()
            removeAllSources()
        }
    }
    
    func removeAllSources() {
        sources.append("hex_linear")
        sources.forEach { (sourceID) in removeSource(sourceID)}
        sources.removeAll()
    }
    
    func convertAndShowHex(_ show: Bool) {
        if show {
            guard let style = mapView.style else { return }
            var geoChord = originalMarker.coordinate.geoCoord
            let index = geoChord.toH3(res: resolution)
            let layer = [index : 0.9]
            let sourceID = "single_hex"
            sources.append(sourceID)
            renderHexer(layer: layer, style: style, sourceId: sourceID, addLineLayer: true)
        } else {
            removeAllLayers()
            removeAllSources()
        }
    }
    
    func refreshLossyMarker(_ show: Bool?) {
        if let v = show, v == false {
            mapView.removeAnnotation(lossMarker)
        } else {
            guard let c = points.first else { return }
            let loss = H3.geojson2h3.convert(toH3: CLLocation(latitude: c.latitude, longitude: c.longitude), res: resolution)
            let center = H3.geojson2h3.convert(from: loss)
            let marker = MGLPointAnnotation()
            marker.coordinate = center
            lossMarker = marker
            mapView.addAnnotation(lossMarker)
        }
    }
    
    func renderPolygonFeature(_ poly: PolygonFeature, source: MGLShapeSource, style: MGLStyle, addLineLayer: Bool) {
        guard let id = poly.identifier?.value else { return }
        let hexLayer = MGLFillStyleLayer(identifier: "fill\(id)", source: source)
        hexLayer.fillColor =  NSExpression(forConstantValue:#colorLiteral(red: 0.9979701638, green: 0.9997151494, blue: 0.8536984324, alpha: 1))
        hexLayer.fillOpacity = NSExpression(forConstantValue: 0.75)
        style.addLayer(hexLayer)
        hexLayers.append(hexLayer)
                        
////                 Create new layer for the line.
        if addLineLayer {
            let lineLayer = MGLLineStyleLayer(identifier: "polyline\(id)", source: source)

            // Set the line join and cap to a rounded end.
            lineLayer.lineJoin = NSExpression(forConstantValue: "round")
            lineLayer.lineCap = NSExpression(forConstantValue: "round")

            // Set the line color to a constant blue color.
            lineLayer.lineColor =  NSExpression(forConstantValue:  #colorLiteral(red: 0.1020374969, green: 0.2753289044, blue: 0.5405613184, alpha: 1))

            // Use `NSExpression` to smoothly adjust the line width from 2pt to 20pt between zoom levels 14 and 18. The `interpolationBase` parameter allows the values to interpolate along an exponential curve.
            lineLayer.lineWidth = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)", [14: 2, 18: 20])

            style.addLayer(lineLayer)
            hexLayers.append(lineLayer)
        }
        
        hexLayers.forEach({$0.isVisible = true})
    }
    
    func renderHexer(layer :  [H3Index : Double], style: MGLStyle, sourceId: String = "hex_linear", addLineLayer: Bool = false) {
        var features : [FeatureVariant] = []
        
        layer.forEach { (arg) in
            let (key , value) = arg
            var valueJSON = AnyJSONType(value.jsonValue)

            if value.isNaN {
                valueJSON = AnyJSONType(0)
            }
            
            features.append(H3.geojson2h3.h3ToFeature(key.toString(), ["value": valueJSON]))
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
                DispatchQueue.main.async { [unowned self] in
                    self.renderPolygonFeature(poly, source: source, style: style, addLineLayer: addLineLayer)
                }
            default:
                print("unknown feature")
            }
        }
    }
    
    func polyfillMap() {
        guard let style = self.mapView.style else { return }
        guard !isLoading else { return }
        
        removeAllLayers()
        removeAllSources()
        
        let coordinateBounds = mapView.visibleCoordinateBounds
        let c1 = coordinateBounds.ne
        let c3 = coordinateBounds.sw
        let c2 = CLLocationCoordinate2D(latitude: c1.latitude, longitude: c3.longitude)
        let c4 = CLLocationCoordinate2D(latitude: c3.latitude, longitude: c1.longitude)
        let sourceID = "polygonHexagons"

        var geoChords = [c1.geoCoord, c2.geoCoord, c3.geoCoord, c4.geoCoord]
        var poly = GeoPolygon(coords: &geoChords)
        var hexs : [H3Index : Double] = [:]

        guard poly.maxPolyfillSize(res: resolution) < 2200 else {
            showMemoryWarning()
            return
        }
        
        guard poly.maxPolyfillSize(res: resolution) > 0 else {
            resolutionError()
            return
        }
        
        poly.polyfill(res: resolution).forEach { hexs[$0] = Double(arc4random())}
        sources.append(sourceID)
        
        DispatchQueue.main.async { [weak self] in
            self?.renderHexer(layer: hexs, style: style, sourceId: sourceID, addLineLayer: true)
            self?.mapView.setVisibleCoordinateBounds(coordinateBounds, animated: true)
            
            //show polygon on top of hexagons
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                self?.renderSinglePolygon(coordinateBounds)
            })
        }
    }
    
    func multiPolyfillMap() {
        guard let style = self.mapView.style else { return }
        guard !isLoading else { return }

        removeAllLayers()
        removeAllSources()

        let coordinateBounds = mapView.visibleCoordinateBounds
        let c1 = coordinateBounds.ne
        let c3 = coordinateBounds.sw
        let c2 = CLLocationCoordinate2D(latitude: c1.latitude, longitude: c3.longitude)
        let c4 = CLLocationCoordinate2D(latitude: c3.latitude, longitude: c1.longitude)
        let sourceID = "polygonHexagons"

        let outerBounds = coordinateBounds.outerBounds
        let o1 = outerBounds.ne
        let o3 = outerBounds.sw
        let o2 = CLLocationCoordinate2D(latitude: o1.latitude, longitude: o3.longitude)
        let o4 = CLLocationCoordinate2D(latitude: o3.latitude, longitude: o1.longitude)
        let oSourceID = "polygonHexagonsOuter"
        
        var geoChords = [c1.geoCoord, c2.geoCoord, c3.geoCoord, c4.geoCoord]
        var oGeoChords = [o1.geoCoord, o2.geoCoord, o3.geoCoord, o4.geoCoord]
        var geoFence = Geofence(coords: &geoChords)
        let oGeoFence = Geofence(coords: &oGeoChords)
        var hexs : [H3Index : Double] = [:]
        var poly = GeoPolygon(geofence: oGeoFence, numHoles: 1, holes: &geoFence)

        guard poly.maxPolyfillSize(res: resolution) < 2200 else {
            showMemoryWarning()
            return
        }
         
        poly.polyfill(res: resolution).forEach { hexs[$0] = Double(arc4random())}
        sources.append(sourceID)
        sources.append(oSourceID)
        
         
         DispatchQueue.main.async { [unowned self] in
             self.renderHexer(layer: hexs, style: style, sourceId: sourceID, addLineLayer: true)
             self.mapView.setVisibleCoordinateBounds(outerBounds, animated: true)
             
             //show polygon on top of hexagons
             DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: { [unowned self] in
                self.renderSinglePolygon(coordinateBounds)
                self.renderSinglePolygon(outerBounds)
             })
         }
     }
    
    func renderSinglePolygon(_ coordinateBounds: MGLCoordinateBounds) {
        guard let style = mapView.style else { return }
        
        let c1 = coordinateBounds.ne
        let c3 = coordinateBounds.sw
        let c2 = CLLocationCoordinate2D(latitude: c1.latitude, longitude: c3.longitude)
        let c4 = CLLocationCoordinate2D(latitude: c3.latitude, longitude: c1.longitude)
        let zoneCoord = [c1, c2, c3, c4]
        let polygon = Polygon([zoneCoord])
        let feature = PolygonFeature(polygon)
        
        let sourceID = "inner_poly\(c1.latitude)" // add some rando so it doesnt dup
        let polyLayerID = "poly\(sourceID)"
        
        let data = try! JSONEncoder().encode(feature)
        let shape = try? MGLShape(data: data, encoding: String.Encoding.utf8.rawValue)
        let source = MGLShapeSource(identifier: sourceID, shape: shape, options: nil)
        
        let polyLayer = MGLFillStyleLayer(identifier: polyLayerID, source: source)
        polyLayer.fillColor =  NSExpression(forConstantValue:#colorLiteral(red: 0.3144622147, green: 0.728943646, blue: 0.7659309506, alpha: 1))
        polyLayer.fillOpacity = NSExpression(forConstantValue: 0.5)
        
        style.addSource(source)
        style.addLayer(polyLayer)
        
        hexLayers.append(polyLayer)
        polygonIDs.append(polyLayerID)
        sources.append(contentsOf: [polyLayerID, sourceID])
    }
}

extension MGLCoordinateBounds {
    var outerBounds: MGLCoordinateBounds {
        let c1 = CLLocationCoordinate2D(latitude: ne.latitude + 5, longitude: ne.longitude + 5)
        let c2 = CLLocationCoordinate2D(latitude: sw.latitude - 5, longitude: sw.longitude - 5)
        return MGLCoordinateBounds(sw: c2, ne: c1)
    }
}
