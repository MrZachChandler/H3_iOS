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
        
        hexColorRange = userInterfaceStyle.medRangeTiny
        resolution = 5
        minMax = (0,100)
        tableView.reloadData()
    }
    
    override func addHexagons(_ completion: @escaping () -> Void) {
        guard let style = mapView.style else {
            completion()
            return
        }

        let id = "census"
        let key = "TRACTCE"
        let resource = "atlanta_censustracts"
        let type = "json"
        
        addHexagonData (
            toStyle: style,
            forSourceID: id,
            withValueKey: key,
            forResource: resource,
            ofType: type,
            completion: completion
        )
    }
}

