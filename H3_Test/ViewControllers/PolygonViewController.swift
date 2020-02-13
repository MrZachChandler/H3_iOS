//
//  PolygonViewController.swift
//  H3_Test
//
//  Created by Zachary Chandler on 2/8/20.
//  Copyright © 2020 Zachary Chandler All rights reserved.
//

import Foundation
import Eureka
import Mapbox
import H3Swift
import Turf
import SnapKit

class PolygonViewController: ExampleViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        resolution = 10
        
        form +++ Section("Core")
            <<< StepperRow("Resolution") {
                $0.title = "Res"
                $0.value = Double(resolution)
                $0.cellUpdate {[unowned self]  (cell, row) in
                    guard let v = row.value else { return }
                    self.resolution = Int32(v)
                }
            }
        
        <<< ButtonRow("Apply") {
            $0.title = "Apply"
            $0.onCellSelection {[unowned self]  (cell, row) in
                DispatchQueue.main.async { [unowned self]  in
                    self.refreshMap()
                }
            }
        }
        
        <<< ButtonRow("Remove") {
            $0.title = "Remove Layer"
            $0.onCellSelection { [unowned self]  (cell, row) in
                cell.textLabel?.textColor = .red
                cell.textLabel?.font = UIFont.boldSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize)
                DispatchQueue.main.async {[unowned self] in
                    self.removeAllLayers()
                }
            }
        }
        tableView.reloadData()
         
    }
    
    func refreshMap() {
        guard !isLoading else { return }
        let coordinateBounds = mapView.visibleCoordinateBounds
        startLoading()
        DispatchQueue.global(qos: .background).async(execute: { [weak self] in
            guard let self = self else { return }
            
            self.createHexagons(coordinateBounds)
        })
    }
    
    func createHexagons(_ coordinateBounds: MGLCoordinateBounds) {
        let c1 = coordinateBounds.ne
        let c3 = coordinateBounds.sw
        let c2 = CLLocationCoordinate2D(latitude: c1.latitude, longitude: c3.longitude)
        let c4 = CLLocationCoordinate2D(latitude: c3.latitude, longitude: c1.longitude)
        
        var geoChords = [c1.geoCoord, c2.geoCoord, c3.geoCoord, c4.geoCoord]
        var poly = GeoPolygon(coords: &geoChords)
        
        let maxPolyfillSize = poly.maxPolyfillSize(res: resolution)
        print(maxPolyfillSize)

        guard maxPolyfillSize < 2200 else {
            showMemoryWarning()
            return
        }
        
        let res: Int32 = resolution
        let indexs = poly.polyfill(res: res)
        
        var hexs : [H3Index : Double] = [:]
        indexs.forEach { (index) in
            hexs[index] = Double(arc4random())
        }
        
        removeAllLayers()
        
        DispatchQueue.main.async { [unowned self] in
            guard let style = self.mapView.style else { return }
            
            if let source = style.source(withIdentifier: "hex_linear") {
                style.removeSource(source)
            }
            
            self.renderHexer(layer: hexs, style: style, addLineLayer: true)
            self.stopLoading()
        }
    }
    
    override func renderPolygonFeature(_ poly: PolygonFeature, source: MGLShapeSource, style: MGLStyle, addLineLayer: Bool) {
            let hex = poly.properties!["hex"]
            let id = hex!.jsonValue as! String
            let range = [
                1: UIColor(red: 253/255, green: 253/255, blue: 217/255, alpha: 1),
                0.5: UIColor(red: 80/255, green: 186/255, blue: 195/255, alpha: 1),
                0.01: UIColor(red: 13/255, green: 35/255, blue: 69/255, alpha: 1)
            ]
            
            let lineRange: [Double : UIColor] = [
                0.25: .white,
                0.5: .gray,
                1: .black
            ]
                            
            let hexLayer = MGLFillStyleLayer(identifier: "fill\(id)", source: source)
//            hexLayer.fillColor = NSExpression(format: "mgl_step:from:stops:(value, %@, %@)", UIColor(red: 13/255, green: 35/255, blue: 69/255, alpha: 1), range)
//            hexLayer.fillOpacity = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)", [13: 20, 17: 0])
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
}
