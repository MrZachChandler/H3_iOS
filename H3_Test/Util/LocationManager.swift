//
//  LocationManager.swift
//  H3_Test
//
//  Created by Zachary Chandler on 11/9/19.
//  Copyright © 2019 Zachary Chandler All rights reserved.
//

import Foundation
import CoreLocation

protocol LocationManagerDelegate {
    func locationManager(_ locationManager: CLLocationManager, didUpdateToLocation location: CLLocation)
}

class LocationManager: NSObject, CLLocationManagerDelegate {
    static let sharedManager = LocationManager()
    fileprivate let sharedLocationManager = CLLocationManager()
    fileprivate var recentLocation = CLLocation(latitude: 33.789, longitude: -84.384) //default becuase demo
    fileprivate var delegates: [AnyObject] = []
    
    fileprivate override init() {
        super.init()
        sharedLocationManager.desiredAccuracy = kCLLocationAccuracyBest
        sharedLocationManager.delegate = self
    }
    
    //MARK: Public Methods
    func startLocationManager() {
        sharedLocationManager.requestWhenInUseAuthorization()
    }
    
    func registerDelegate(_ delegate: AnyObject) {
        delegates.append(delegate)
        notifyLocationUpdateDelegates()
    }
    
    func unregisterDelegate(_ delegate: AnyObject) {
        delegates = delegates.filter({$0 !== delegate})
    }
    
    //MARK: CLLocationManager Delegate
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .notDetermined {
            sharedLocationManager.requestWhenInUseAuthorization()
        }
        else if status == .restricted || status == .denied {
            //give it a default cause this is a demo and everything in ATL
            recentLocation = CLLocation(latitude: 33.789, longitude: -84.384)
            notifyLocationUpdateDelegates()
        }
        else if status == .authorizedAlways || status == .authorizedWhenInUse {
            sharedLocationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if locations.count > 0 {
            recentLocation = locations[0]
            notifyLocationUpdateDelegates()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("\(error.localizedDescription)")
    }
    
    //MARK: Helpers
    fileprivate func notifyLocationUpdateDelegates() {
        for delegate in delegates {
            (delegate as! LocationManagerDelegate).locationManager(sharedLocationManager, didUpdateToLocation: recentLocation)
        }
    }
}
