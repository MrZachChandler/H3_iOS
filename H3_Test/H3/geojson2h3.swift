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
                return flatten(polygonToH3Index(polygon, resolution: resolution))
            case .multiPolygonFeature(let multiPolygonFeature):
                return flatten(multiPolygonToH3Index(multiPolygonFeature, resolution: resolution))
            case .pointFeature(let point):
                var geo = point.geometry.coordinates.geoCoord
                return [geo.toH3(res: resolution).toString()]
            case .lineStringFeature(let line):
                return convert(line.geometry.coordinates, at: resolution)
            case .multiPointFeature(let multiPoint):
                return convert(multiPoint.geometry.coordinates, at: resolution)
            case .multiLineStringFeature(let multiLine):
                return convert(multiLine.geometry.coordinates, at: resolution)
            }
        }
        
        static func convert(_ coordinates: [CLLocationCoordinate2D], at res: Int32) -> [String] {
            var strings: [String] = []
            coordinates.forEach {
                var geo = $0.geoCoord
                strings.append(geo.toH3(res: res).toString())
            }
            return Array(Set(strings))
        }
        
        static func convert(_ coordinates: [[CLLocationCoordinate2D]], at res: Int32) -> [String] {
            var strings: [[String]] = []
            coordinates.forEach { strings.append(convert($0, at: res))}
            return Array(Set(flatten(strings)))
        }
        
        static func convert(toH3 location: CLLocation , res: Int32) -> H3Swift.H3Index {
            var coordinate = location.geoCoord
            return coordinate.toH3(res: res)
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
            return h3ToFeature(H3Swift.H3Index.init(string: addressString), properties)
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

        static func h3ToGeoBoundary(from index: H3Swift.H3Index) -> [CLLocationCoordinate2D] {
            return index.geoBoundary().coordinates
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
            
            hexagons.forEach {
                let properties = getProperties($0)
                let feature = h3ToFeature($0.toString(), properties)
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
        var geoCoord = GeoCoord()
        geoCoord.lat = H3.geojson2h3.deg2rad(latitude)
        geoCoord.lon = H3.geojson2h3.deg2rad(longitude)
        return geoCoord
    }
}
extension CLLocationCoordinates2D {
    var geoCoords: [GeoCoord] {
        var asGeoCoords: [GeoCoord] = []
        forEach { asGeoCoords.append($0.geoCoord) }
        return asGeoCoords
    }
}
typealias StringsStrings = [[String]]
extension StringsStrings {
    var h3Indexs: [[H3Index]] {
        var h3Indexs: [[H3Index]] = [[]]
        forEach{h3Indexs.append($0.h3Indexs)}
        return h3Indexs
    }
}

typealias Strings = [String]
extension Strings {
    var h3Indexs: [H3Index] {
        var h3Indexs: [H3Index?] = []
        forEach { h3Indexs.append($0.h3Index)}
        return h3Indexs.filter { return $0 != nil } as! [H3Index]
    }
}
extension String {
    var h3Index: H3Index? {
        return H3Swift.H3Index.init(string: self)
    }
}

extension Double {
    func normalize(min: Double, max: Double, from a: Double = 0, to b: Double = 1) -> Double {
        return (b - a) * ((self - min) / (max - min)) + a
    }
}

extension CLLocation {
    var geoCoord: GeoCoord {
        var geoCoord = GeoCoord()
        geoCoord.lat = H3.geojson2h3.deg2rad(coordinate.latitude)
        geoCoord.lon = H3.geojson2h3.deg2rad(coordinate.longitude)
        return geoCoord
    }
}
