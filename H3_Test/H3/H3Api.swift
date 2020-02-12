//
//  H3Api.swift
//  H3_Test
//
//  Created by Zachary Chandler on 11/9/19.
//  Copyright © 2019 Routematch Software, Inc. All rights reserved.
//

import Foundation
import CoreLocation
import H3
import H3Swift
import Mapbox
import Turf

final class H3: NSObject {
    static let API = H3()
    
    fileprivate override init() {
        
    }
    
    func deg2rad(_ number: Double) -> Double {
        return number * .pi / 180
    }
    
    func rad2deg(_ number: Double) -> Double {
        return number * 180 / .pi
    }
    
    func convert(toH3 location: CLLocation , res: Int32) -> H3Swift.H3Index {
        var coordinate = GeoCoord()
        coordinate.lat = deg2rad(location.coordinate.latitude)
        coordinate.lon = deg2rad(location.coordinate.longitude)
        
        let k = coordinate.toH3(res: res)
        return k
    }
    
    func convert(from index: H3Swift.H3Index) -> CLLocationCoordinate2D {
        return GeoCoord.from(index).coordinate
    }
    
   
    func generatePolygon(from location: CLLocation, res: Int32) -> [CLLocationCoordinate2D] {
        let index = convert(toH3: location, res: res)
        return convertGeoCoord(from: index)
    }

    func convertGeoCoord(from k: H3Swift.H3Index) -> [CLLocationCoordinate2D] {
        var arr: [CLLocationCoordinate2D] = []

        k.geoBoundary().forEach { (coor) in
            arr.append(coor.coordinate)
        }

        return arr
    }
    
    func generateBase() {
//        let h3 = H3Swift.H3Index.
    }
}

extension GeoCoord {
    var coordinate: CLLocationCoordinate2D {
        let lati =  rad2deg( constrainLat(lati: lat))
        let longi = rad2deg(constrainLng(lng: lon))
        
        return CLLocationCoordinate2D(latitude: lati, longitude: longi)
    }
    
    func deg2rad(_ number: Double) -> Double {
        return number * .pi / 180
    }
    
    func rad2deg(_ number: Double) -> Double {
        return number * 180 / .pi
    }
    
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

extension CLLocationCoordinate2D {
    var geoCoord: GeoCoord {
        var c = GeoCoord()
        c.lat = deg2rad(latitude)
        c.lon = deg2rad(longitude)
        return c
    }
    
    func deg2rad(_ number: Double) -> Double {
        return number * .pi / 180
    }
    
    func rad2deg(_ number: Double) -> Double {
        return number * 180 / .pi
    }
    
}
