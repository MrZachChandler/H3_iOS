//
//  H3MapDelegate.swift
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

protocol H3MapDelegate: AnyObject {
    var resolution: Int32 { get set }
    var mapView: MGLMapView! { get set }
    var hexLayers: [MGLStyleLayer] { get set }
}

extension H3MapDelegate {
    typealias MinMax = (Double,Double)

    func animateTo(location: CLLocation?) {
        if let center = location?.coordinate {
            let camera = MGLMapCamera(lookingAtCenter: center, altitude: 8000, pitch: 15, heading: 360)
             
                // Animate the camera movement over 5 seconds.
                mapView.setCamera(camera, withDuration: 5, animationTimingFunction: CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut))
        }
    }
    
    func removeAllLayers() {
        hexLayers.forEach { removeLayer(layerIdentifier: $0.identifier, removeSource: true) }
        hexLayers.removeAll()
    }
    
    func removeSource(_ sourceID: String) {
        guard let map = mapView else { return }
        guard let mapStyle = map.style else { return }
        
        guard let source = mapStyle.source(withIdentifier: sourceID) else {
            print("no source found with id: \(sourceID)")
            return
        }
        
        mapStyle.removeSource(source)
        print("removed source with id: \(sourceID)")
    }
    
    func removeLayer(layerIdentifier: String, removeSource: Bool = false){
        guard let map = mapView else { return }
        guard let currentLayers = map.style?.layers else { return }
        
        if currentLayers.filter({ $0.identifier == layerIdentifier}).first != nil {
            print("Layer \(layerIdentifier) found.")

            guard let mapStyle = map.style else { return }
            
            // remove layer first
            if let styleLayer = mapStyle.layer(withIdentifier: layerIdentifier) {
                mapStyle.removeLayer(styleLayer)
            }
            
            // then remove the source
            if removeSource {
                if let source = mapStyle.source(withIdentifier: layerIdentifier) {
                    print("Removing source with ID: \(source.identifier)")
                    mapStyle.removeSource(source)
                }
            }
        }
        else {
            print("No layer with the identifier \(layerIdentifier) found.")
        }
    }

    func countPoints(_ collection: FeatureCollection, normalize: MinMax? = nil) -> [H3Index : Double]  {
        var layer: [H3Index : Double] = [:]

        collection.features.forEach {
            guard let point = $0.value as? PointFeature else { return }
            
            let index = H3.geojson2h3.convert(toH3: CLLocation(latitude: point.geometry.coordinates.latitude, longitude: point.geometry.coordinates.longitude), res: resolution)
            let option = layer[index] == nil
            let value: Double = option ? 0 : layer[index]!
            layer[index] = value + 1
        }
        
        return normalizeData(layer)
    }
    
    func bufferPoints(_ collection: FeatureCollection, radius: Int32, normalize: MinMax? = nil) -> [H3Index : Double] {
         var layer: [H3Index : Double] = [:]
             
         collection.features.forEach {
            guard let point = $0.value as? PointFeature else { return }
          
            let baseIndex = H3.geojson2h3.convert(toH3: CLLocation(latitude: point.geometry.coordinates.latitude, longitude: point.geometry.coordinates.longitude), res: resolution)
             let rings = baseIndex.kRingDistances(k: radius)
              
             //make sure you count the base index
             let option = layer[baseIndex] == nil
             let value: Double = option ? 0 : layer[baseIndex]!
             layer[baseIndex] = value + 1
             
             rings.forEach { (ring) in
                 ring.forEach { (index) in
                     let option = layer[index] == nil
                     let value: Double = option ? 0 : layer[index]!
                     let cal = value + 1
                     layer[index] = cal
                 }
             }
         }
    
         return normalizeData(layer)
     }
        
    func bufferPointsLinear(_ collection: FeatureCollection, radius: Int32, normalize: MinMax? = nil) -> [H3Index : Double] {
        var layer: [H3Index : Double] = [:]
            
        collection.features.forEach {
            guard let point = $0.value as? PointFeature else { return }

            let baseIndex = H3.geojson2h3.convert(toH3: CLLocation(latitude: point.geometry.coordinates.latitude, longitude: point.geometry.coordinates.longitude), res: resolution)
            let rings = baseIndex.kRingDistances(k: radius)
            let step: Double = 1 / Double(radius + 1)
            
            //distance is the index of first array but also the number away from the center hexagon
            var distance: Double = 0
             
            //make sure you count the base index
            let option = layer[baseIndex] == nil
            let value: Double = option ? 0 : layer[baseIndex]!
            layer[baseIndex] = value + 1
            
            rings.forEach { (ring) in
                ring.forEach { (index) in
                    let option = layer[index] == nil
                    let value: Double = option ? 0 : layer[index]!
                    let cal = value + 1 - distance * step
                    layer[index] = cal
                }
                distance += 1
            }
        }
   
        return normalizeData(layer)
    }
    
    func normalizeData(_ layer: [H3Index : Double], zeroBaseLine: Bool = false, normalize: MinMax? = nil) -> [H3Index:Double] {
        var max = normalize?.0 ?? -1.0
        var min = normalize?.1 ?? 1000000.0
        var layers = layer
        
        if normalize == nil {
            //first pass find min and max
            layer.forEach {
                if $0.1 > max { max = $0.1 }
                if $0.1 < min { min = $0.1 }
            }
        }
    
        // second pass normalize
        layers.forEach {
            let (key, value) = $0
            let result = abs(value.normalize(min: min, max: max))
            layers[key] = result
        }
        
        return layers
    }
}
