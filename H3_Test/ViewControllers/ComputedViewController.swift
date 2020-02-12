//
//  ComputedViewController.swift
//  H3_Test
//
//  Created by Zachary Chandler on 2/10/20.
//  Copyright © 2020 Routematch Software, Inc. All rights reserved.
//

import Foundation
import Foundation
import Eureka
import Mapbox
import H3Swift
import Turf
import SnapKit

class ComputedViewController: ExampleViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        resolution = 10
        
    }
    
    func compute() {
        let options : [MGLShapeSourceOption : Any]? = nil
        let source = MGLComputedShapeSource(identifier: "computed", dataSource: self, options: options)
    }
}

typealias ComputedFeature = [MGLShape & MGLFeature]
extension ComputedViewController: MGLComputedShapeSourceDataSource {
    func featuresInTileAt(x: UInt, y: UInt, zoomLevel: UInt) -> [MGLShape & MGLFeature] {
        let shape = MGLShape()
        let feature = MGLPolygonFeature()
        let computedFeaturee = [shape, feature]
        return computedFeaturee as! [MGLShape & MGLFeature]
    }
    
    func features(in bounds: MGLCoordinateBounds, zoomLevel: UInt) -> [MGLShape & MGLFeature] {
        let shape = MGLShape()
        let feature = MGLPolygonFeature()
        let computedFeaturee = [shape, feature]
        return computedFeaturee as! [MGLShape & MGLFeature]
    }
}
