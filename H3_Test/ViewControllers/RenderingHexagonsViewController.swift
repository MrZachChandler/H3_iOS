//
//  RenderingHexagonsViewController.swift
//  H3_Test
//
//  Created by Zachary Chandler on 2/20/20.
//  Copyright © 2020 Zachary Chandler All rights reserved.
//

import Foundation
import Turf
import H3Swift
import Eureka
import Mapbox

class RenderingHexagonsViewController: ExampleViewController {
    let valueKey = "value"
    var keepRes = false
    var stopAnimating = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        hexColorRange = userInterfaceStyle.shortRange
        minMax = (0,1)
        
        form +++ Section("") {
                    $0.footer = HeaderFooterView(title: "Control")
                }

                <<< SwitchRow("keeep") {
                    $0.title = "keepResolution"
                    $0.value = false
                    $0.onChange { [unowned self]  (row) in
                        guard let v = row.value else { return }
                        self.keepRes = v
                    }
                }
            
                <<< SwitchRow("stop") {
                    $0.title = "Stop Animating"
                    $0.value = false
                    $0.onChange { [unowned self]  (row) in
                        guard let v = row.value else { return }
                        self.stopAnimating = v
                    }
                }
        
        
        tableView.reloadData()
    }
    
    override func addHexagons(_ completion: @escaping () -> Void) {
        guard let style = mapView.style else {
            completion()
            return
        }
        
        let id = "hex_linear"
        let key = valueKey
        let resource = ""
        let type = ""
        
        addHexagonData (
            toStyle: style,
            forSourceID: id,
            withValueKey: key,
            forResource: resource,
            ofType: type,
            completion: completion
        )
    }
    
    
    // removing for cpu
    override func startLoading() { }
    override func stopLoading() { }
    
    override func getlocalData(forResource resource: String, ofType type: String) -> FeatureCollection? {
        var points: [FeatureVariant] = []
        
        randomCoordinates.forEach {
            let point = Point($0)
            let feature = PointFeature(point)
            let variant = FeatureVariant.pointFeature(feature)
            points.append(variant)
        }
        
        let pointFeatureCollection = FeatureCollection(points)
        let layer = bufferPointsLinear(pointFeatureCollection, radius: 2)
        
        return layerToFeatureCollection(layer: layer, valueKey: valueKey)
    }
    
    override func mapViewRegionIsChanging(_ mapView: MGLMapView) {
        guard !keepRes else { return }
        DispatchQueue.main.async {
            [weak self] in
            guard let self = self else { return }
            self.resolution = self.resolutionFor(zoom: mapView.zoomLevel)
        }
    }
    
    override func mapViewDidBecomeIdle(_ mapView: MGLMapView) {
        guard !stopAnimating else { return }
        DispatchQueue.main.async {
            [weak self] in
            self?.addHexagons { }
        }
    }
}


extension RenderingHexagonsViewController {
    var randomCoordinates: [CLLocationCoordinate2D] {
        var coordinates: [CLLocationCoordinate2D] = []
        var count = 32
        
        while count > 0 {
            coordinates.append(getRandCoordinate())
            count -= 1
        }
        
        return coordinates
    }
    
    func getRandCoordinate() -> CLLocationCoordinate2D {
        let min = arc4random_uniform(10000)
        let max = arc4random_uniform(10000)

        return generateRandomCoordinates(min: min, max: max)
    }
    
    func generateRandomCoordinates(min: UInt32, max: UInt32) -> CLLocationCoordinate2D {
        let currentLocation = curLocation
        let currentLong = currentLocation.coordinate.longitude
        let currentLat = currentLocation.coordinate.latitude

        //1 KiloMeter = 0.00900900900901° So, 1 Meter = 0.00900900900901 / 1000
        let meterCord = 0.00900900900901 / 1000

        //Generate random Meters between the maximum and minimum Meters
        let randomMeters = UInt(arc4random_uniform(max) + min)

        //then Generating Random numbers for different Methods
        let randomPM = arc4random_uniform(6)

        //Then we convert the distance in meters to coordinates by Multiplying the number of meters with 1 Meter Coordinate
        let metersCordN = meterCord * Double(randomMeters)

        //here we generate the last Coordinates
        if randomPM == 0 {
            return CLLocationCoordinate2D(latitude: currentLat + metersCordN, longitude: currentLong + metersCordN)
        } else if randomPM == 1 {
            return CLLocationCoordinate2D(latitude: currentLat - metersCordN, longitude: currentLong - metersCordN)
        } else if randomPM == 2 {
            return CLLocationCoordinate2D(latitude: currentLat + metersCordN, longitude: currentLong - metersCordN)
        } else if randomPM == 3 {
            return CLLocationCoordinate2D(latitude: currentLat - metersCordN, longitude: currentLong + metersCordN)
        } else if randomPM == 4 {
            return CLLocationCoordinate2D(latitude: currentLat, longitude: currentLong - metersCordN)
        } else {
            return CLLocationCoordinate2D(latitude: currentLat - metersCordN, longitude: currentLong)
        }
    }
}
