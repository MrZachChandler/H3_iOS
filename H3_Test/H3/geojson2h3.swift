//
//  geojson2h3.swift
//  H3_Test
//
//  Created by Zachary Chandler on 1/26/20.
//  Copyright © 2020 Routematch Software, Inc. All rights reserved.
//

import Foundation
import Turf
import H3Swift
import CoreLocation

extension H3 {






enum geojson2h3 {
    
    static func deg2rad(_ number: Double) -> Double {
        return number * .pi / 180
    }
    
    static func rad2deg(_ number: Double) -> Double {
        return number * 180 / .pi
    }
        
    static func flatten(_ arrays: [[String]]) -> [String] {
        return Array(arrays.joined())
    }
    
    static func featureCollectionToH3Set(_ collection: FeatureCollection?, _ resolution: Int32 ) -> [String]? {
        guard let featureCollection = collection else { return nil }
        return flatten(featureCollection.features.compactMap({ feature -> [String]? in return featureToH3Set(feature, resolution) }))
    }
    
    static func h3Distance(from index: H3Index, to hex: H3Index) -> Double {
        let c1 = GeoCoord.from(index)
        let c2 = GeoCoord.from(hex)
        let a = c1.coordinate
        let b = c2.coordinate
        return a.distance(to: b)
    }


    static func featureToH3Set(_ feature: FeatureVariant?, _ resolution: Int32) -> [String]? {
        guard let feature = feature else { return [] }
        
        switch feature {
        case .polygonFeature(let polygon):
            print("polygonFeature")
            return flatten(polygonToH3Index(polygon, resolution: resolution))
        case .multiPolygonFeature(let multiPolygonFeature):
            return flatten(multiPolygonToH3Index(multiPolygonFeature, resolution: resolution))
        default:
            return nil
        }
    }
    
    static func polygonToH3Index(_ polygon: PolygonFeature, resolution: Int32) -> [[String]] {
        return polygon.geometry.coordinates.compactMap { (coordinates) ->  [String]? in
        
            var geoCoords = coordinates.compactMap { (c) -> GeoCoord? in
                var coordinate = GeoCoord()
                coordinate.lat = deg2rad(c.latitude)
                coordinate.lon = deg2rad(c.longitude)
                return coordinate
            }
        
            var h3Poly = GeoPolygon.init(coords: &geoCoords)
            return h3Poly.polyfill(res: resolution).compactMap { (index) -> String? in return index.toString() }
        }
    }
    
    
    static func coordinatesToH3Index(_ coordinates: [CLLocationCoordinate2D], resolution: Int32) -> [String] {
        var geoCoords = coordinates.compactMap { (c) -> GeoCoord? in
                var coordinate = GeoCoord()
                coordinate.lat = deg2rad(c.latitude)
                coordinate.lon = deg2rad(c.longitude)
                return coordinate
            }

        var h3Poly = GeoPolygon.init(coords: &geoCoords)
        
        return h3Poly.polyfill(res: resolution).compactMap { (index) -> String in return index.toString() }
    }
    
    static func coordinatesToH3Index(_ coordinates: [[CLLocationCoordinate2D]], resolution: Int32) -> [[String]] {
       return coordinates.compactMap { (c) ->  [String]? in return coordinatesToH3Index(c, resolution: resolution) }
    }
    
    static func multiPolygonToH3Index(_ polygons: MultiPolygonFeature, resolution: Int32) -> [[String]] {
        return polygons.geometry.coordinates.compactMap { (cooridnates2D) -> [String]?  in
            return flatten(coordinatesToH3Index(cooridnates2D, resolution: resolution))
        }
    }
    
    static func h3ToFeature(_ addressString: String, _ properties: FeatureProperties = FeatureProperties.none) -> FeatureVariant {
        let index = H3Swift.H3Index.init(string: addressString)
        //normalize to multipolygon
        let multi = [h3ToGeoBoundary(from: index)]
        
        var feature = PolygonFeature(Polygon(multi))
        feature.identifier = FeatureIdentifier.string(addressString)
        feature.properties = properties
        feature.geometry = Polygon(multi)
        feature.type = .feature
        
        return FeatureVariant.polygonFeature(feature)
    }

    static func h3ToGeoBoundary(from k: H3Swift.H3Index) -> [CLLocationCoordinate2D] {
        var arr: [CLLocationCoordinate2D] = []

        k.geoBoundary().forEach { (coor) in
            arr.append(coor.coordinate)
        }

        return arr
    }
    
    static func h3SetToFeature(_ hexagons: [H3Swift.H3Index], _ properties: FeatureProperties = FeatureProperties.none) -> FeatureVariant {
        return FeatureVariant.multiPolygonFeature(h3SetToMultiPolygon(hexagons, properties))
    }
    
    static func h3SetToMultiPolygon(_ hexagons: [H3Swift.H3Index], _ properties: FeatureProperties = FeatureProperties.none) -> MultiPolygonFeature {
        let coordinates = hexagons.map { index  in
            return [h3ToGeoBoundary(from: index)]
        }
        
        let shape = MultiPolygon(coordinates)
        var multiPolygon = MultiPolygonFeature(shape)
        multiPolygon.properties = properties
        multiPolygon.type = .feature
        
        return multiPolygon
    }
    
    static func getProperties(_ index: H3Index) -> FeatureProperties {
        return FeatureProperties.none
    }
    
    static func h3SetToFeatureCollection(_ hexagons: [H3Swift.H3Index], _ properties: FeatureProperties ) -> FeatureCollection {
        var features: [FeatureVariant] = []
        
        hexagons.forEach { index in
            let properties = getProperties(index)
            let feature = h3ToFeature(index.toString(), properties)
            features.append(feature)
            
        }
        
        var featureCollection = FeatureCollection(features)
        featureCollection.type = .featureCollection
        featureCollection.properties = properties
        return featureCollection
    }
    
}

typealias FeatureProperties = [String : AnyJSONType]?

}
