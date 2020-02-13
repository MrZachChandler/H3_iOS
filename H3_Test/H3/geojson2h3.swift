//
//  geojson2h3.swift
//  H3_Test
//
//  Created by Zachary Chandler on 1/26/20.
//  Copyright © 2020 Zachary Chandler All rights reserved.
//

import Turf
import H3Swift
import CoreLocation

typealias FeatureProperties = [String : AnyJSONType]?
typealias CLLocationCoordinates2D = [CLLocationCoordinate2D]
typealias GeoCoords = [GeoCoord]

enum H3 {
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
        
        static func convert(toH3 location: CLLocation , res: Int32) -> H3Swift.H3Index {
            var coordinate = GeoCoord()
            coordinate.lat = deg2rad(location.coordinate.latitude)
            coordinate.lon = deg2rad(location.coordinate.longitude)
            
            let k = coordinate.toH3(res: res)
            return k
        }
        
        static func convert(from index: H3Swift.H3Index) -> CLLocationCoordinate2D {
            return GeoCoord.from(index).coordinate
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
            return h3ToFeature(index, properties)
        }
        
        static func h3ToFeature(_ index: H3Index, _ properties: FeatureProperties = FeatureProperties.none) -> FeatureVariant {
            let multi = [h3ToGeoBoundary(from: index)]
            let polygon = Polygon(multi)
            
            var feature = PolygonFeature(polygon)
            feature.identifier = FeatureIdentifier.string(index.toString())
            feature.properties = properties
            feature.type = .feature
            
            return FeatureVariant.polygonFeature(feature)
        }

        static func h3ToGeoBoundary(from k: H3Swift.H3Index) -> [CLLocationCoordinate2D] {
            var arr: [CLLocationCoordinate2D] = []
            k.geoBoundary().forEach { arr.append($0.coordinate) }
            return arr
        }
        
        static func h3SetToFeature(_ hexagons: [H3Swift.H3Index], _ properties: FeatureProperties = FeatureProperties.none) -> FeatureVariant {
            return FeatureVariant.multiPolygonFeature(h3SetToMultiPolygon(hexagons, properties))
        }
        
        static func h3SetToMultiPolygon(_ hexagons: [H3Swift.H3Index], _ properties: FeatureProperties = FeatureProperties.none) -> MultiPolygonFeature {
            let coordinates = hexagons.map { return [h3ToGeoBoundary(from: $0)] }
            let shape = MultiPolygon(coordinates)
            var multiPolygon = MultiPolygonFeature(shape)
            multiPolygon.properties = properties
            multiPolygon.type = .feature
            
            return multiPolygon
        }
        
        static func getProperties(_ index: H3Index) -> FeatureProperties {
            return FeatureProperties(["index" : AnyJSONType(index.toString())])
        }
        
        static func h3SetToFeatureCollection(_ hexagons: [H3Swift.H3Index], _ properties: FeatureProperties) -> FeatureCollection {
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
}


/// - NOTE: Convience functions for Coordinartes Translations

extension GeoCoord {
    var coordinate: CLLocationCoordinate2D {
        let latitude =  H3.geojson2h3.rad2deg(constrainLat(lati: lat))
        let longitude = H3.geojson2h3.rad2deg(constrainLng(lng: lon))
        
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    /**
     * constrainLat makes sure latitudes are in the proper bounds
     *
     * @param lng The origin lng value
     * @return The corrected lng value
     */
    func constrainLat(lati: Double) -> Double {
        var latit = lati
        while (latit > .pi) {
            latit = lat - .pi;
        }
        return latit;
    }

    /**
     * constrainLng makes sure longitudes are in the proper bounds
     *
     * @param lng The origin lng value
     * @return The corrected lng value
     */
    func constrainLng(lng: Double) -> Double {
        var long = lng
        while (long > .pi) {
            long = long - (2 * .pi);
        }
        while (long < -.pi) {
            long = long + (2 * .pi);
        }
        return long;
    }
}

extension GeoCoords {
    var coordinates: CLLocationCoordinates2D {
        var coordinates: CLLocationCoordinates2D = []
        forEach {coordinates.append($0.coordinate)}
        return coordinates
    }
}

extension CLLocationCoordinate2D {
    var geoCoord: GeoCoord {
        var c = GeoCoord()
        c.lat = H3.geojson2h3.deg2rad(latitude)
        c.lon = H3.geojson2h3.deg2rad(longitude)
        return c
    }
}
extension CLLocationCoordinates2D {
    var geoCoords: [GeoCoord] {
        var asGeoCoords: [GeoCoord] = []
        forEach { asGeoCoords.append($0.geoCoord) }
        return asGeoCoords
    }
}

extension String {
    var h3Index: H3Index? {
        return H3Swift.H3Index.init(string: self)
    }
}
