//
//  PointLayerViewController.swift
//  H3_Test
//
//  Created by Zachary Chandler on 2/5/20.
//  Copyright © 2020 Routematch Software, Inc. All rights reserved.
//

import Foundation
import Mapbox
import NotificationBanner
import Eureka
import Turf

class PointLayerViewController: ClusterViewController {
    var points:[CLLocationCoordinate2D] = []
    var originalMarker: MGLPointAnnotation!
    var lossMarker: MGLPointAnnotation!

    override func viewDidLoad() {
        super.viewDidLoad()
        let c = CLLocationCoordinate2D(latitude: 33.789, longitude: -84.384)
        points.append(c)
                    
        mapView.showsUserLocation = false
        
        let marker = MGLPointAnnotation()
        marker.coordinate = c
        originalMarker = marker
        
        mapView.addAnnotation(marker)
        addSinglePointLayer()
        tableView.reloadData()
    }
        
    func addSinglePointLayer() {
        let section = Section("Point")
            <<< StepperRow("Resolution") {
                $0.title = "Res"
                $0.value = Double(resolution)
                $0.cellUpdate { (cell, row) in
                    guard let v = row.value else { return }
                    self.resolution = Int32(v)
                }
            }
            
            <<< SwitchRow("Convert Point to Hex") {
                $0.title = "Convert to Hex"
                $0.value = false
                $0.onChange { (row) in
                    guard let vis = row.value else { return }
                    self.convertAndShowHex(vis)
                    
                }
            }
            
            <<< SwitchRow("lossy") {
                $0.title = "Show Data Loss"
                $0.value = false
                $0.onChange { (row) in
                    self.refreshLossyMarker(row.value)
                }
            }
            
            <<< ButtonRow("Apply") {
                $0.title = "Apply"
                $0.onCellSelection { (cell, row) in
                    DispatchQueue.main.async {
                        //refresh
                    }
                }
            }
        
        form.insert(section, at: 0)
    }
    
    func convertAndShowHex(_ show: Bool) {
        if show {
            guard let style = mapView.style else { return }
            renderHexs(style: style)
        }
        
        hexLayers?.forEach({ (hex) in
            hex.isVisible = show
        })
    }
    
    func refreshLossyMarker(_ show: Bool?) {
        if let v = show, v == false {
            mapView.removeAnnotation(lossMarker)
        } else {
            guard let c = points.first else { return }
            let loss = H3.API.convert(toH3: CLLocation(latitude: c.latitude, longitude: c.longitude), res: resolution)
            let center = H3.API.convert(from: loss)
            let marker = MGLPointAnnotation()
            marker.coordinate = center
            lossMarker = marker
            mapView.addAnnotation(lossMarker)
        }
    }
    
    
    
    func renderHexs(style: MGLStyle) {
        guard let c = points.first else { return }
        
        let index = H3.API.convert(toH3: CLLocation(latitude: c.latitude, longitude: c.longitude), res: resolution).toString()
        let hexagon = H3.geojson2h3.h3ToFeature(index, ["value": AnyJSONType(1), "hex": AnyJSONType(index)])
        
        if hexLayers == nil { hexLayers = [] }
        else { removeAllLayers() }
        
        switch hexagon {
        case .polygonFeature(let poly):
            let data = try! JSONEncoder().encode(poly)
            let shape = try? MGLShape(data: data, encoding: String.Encoding.utf8.rawValue)
            let source = MGLShapeSource(identifier: "hex_linear", shape: shape, options: nil)
            let hexLayer = MGLFillStyleLayer(identifier: "fill\(index)", source: source)
            let range = [
                0.25: UIColor(red: 253/255, green: 253/255, blue: 217/255, alpha: 0.75),
                0.5: UIColor(red: 80/255, green: 186/255, blue: 195/255, alpha: 0.75),
                1: UIColor(red: 13/255, green: 35/255, blue: 69/255, alpha: 0.75)
            ]
            
            print(String(data: data, encoding: .utf8) ?? "")
            
            style.addSource(source)

            hexLayer.fillColor = NSExpression(format: "mgl_step:from:stops:(value, %@, %@)", UIColor(red: 253/255, green: 253/255, blue: 217/255, alpha: 0.75), range)
            hexLayer.fillOpacity = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)", [14: 2, 18: 20])
            
            style.addLayer(hexLayer)
            hexLayers!.append(hexLayer)
             
            
            // Create new layer for the line.
            let lineLayer = MGLLineStyleLayer(identifier: "polyline\(index)", source: source)

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
            hexLayers?.forEach({ (l) in
                l.isVisible = false
            })
        default:
            return
        }
    }
}
