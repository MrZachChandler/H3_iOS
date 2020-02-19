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
        resolution = 5
        
        form +++ Section("Core Functions") {
            $0.footer = HeaderFooterView(title: "ATL Census Data!")
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
            guard let style = self.mapView.style else { return }
            self.addData(style)
        })
    
        tableView.reloadData()
    }
    
    func addData(_ style: MGLStyle) {
        startLoading()
        addCensusTrackData(style) { [weak self] in self?.stopLoading() }
    }
    
    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        addData(style)
    }
    
    func addCensusTrackData(_ style: MGLStyle, _ block: @escaping () -> Void) {
        let sourceID = "census"
        
        DispatchQueue.global(qos: .background).async(execute: { [weak self] in
            defer { DispatchQueue.main.async { block() } }
            guard let featureCollection = self?.getCensusData() else { return }
            guard let data = self?.createHexLayer(featureCollection: featureCollection) else { return }
            guard let shape = try? MGLShape(data: data, encoding: String.Encoding.utf8.rawValue) else { return }
            guard let source = style.source(withIdentifier: sourceID) as? MGLShapeSource else {
                DispatchQueue.main.async { self?.createSource(style: style, shape: shape, sourceID: sourceID) }
                return
            }
            
            DispatchQueue.main.async { source.shape = shape }
        })
    }
    
    func getCensusData() -> FeatureCollection? {
        guard let path = Bundle.main.path(forResource: "atlanta_censustracts", ofType: "json") else { return nil }
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe) else { return nil }
        return try? JSONDecoder().decode(FeatureCollection.self, from: data)
    }
    
    func createHexLayer(featureCollection: FeatureCollection) -> Data? {
        var layers: [H3Index: Double] = [:]
        var features : [FeatureVariant] = []
        var min = 10000000.0
        var max = -1.0
        
        for feature in featureCollection.features {
            guard let poly = feature.value as? PolygonFeature else { continue }
            let v = poly.properties?["TRACTCE"]
            if let s = v?.jsonValue as? String, let d = Double(s) {
                if d < min { min = d }
                if d > max {max = d }
            }
        }
        
        for feature in featureCollection.features {
            guard let hexagons = H3.geojson2h3.featureToH3Set(feature, resolution) else { continue }
            guard let poly = feature.value as? PolygonFeature, let v = poly.properties?["TRACTCE"]?.jsonValue as? String, let value = Double(v) else { continue }
            
            let indexs = hexagons.h3Indexs
            indexs.forEach{layers[$0] = value.normalize(min: min, max: max, from: 0, to: 100)}
        }
            
        layers.forEach { (key , value) in
            var valueJSON = AnyJSONType(value.jsonValue)
            if value.isNaN { valueJSON = AnyJSONType(0) }
            features.append(H3.geojson2h3.h3ToFeature(key.toString(), ["value": valueJSON]))
        }
        
        return try? JSONEncoder().encode(FeatureCollection(features))
    }
    
    func createSource(style: MGLStyle, shape: MGLShape, sourceID: String) {
        let source = MGLShapeSource(identifier: sourceID, shape: shape, options: nil)
        let hexLayer = MGLFillStyleLayer(identifier: sourceID, source: source)
        hexLayer.fillColor = NSExpression(format: "mgl_step:from:stops:(value, %@, %@)", #colorLiteral(red: 0.004857238848, green: 0, blue: 0.1536510587, alpha: 1), userInterfaceStyle.medRange)
        hexLayer.fillOpacity = NSExpression(forConstantValue: 0.75)
        hexLayer.fillOutlineColor = NSExpression(forConstantValue: userInterfaceStyle.textColor)
        
        DispatchQueue.main.async {
            style.addLayer(hexLayer)
            style.addSource(source)
        }
        
        hexLayers.append(hexLayer)
    }
}
