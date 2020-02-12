//
//  Examples.swift
//  H3_Test
//
//  Created by Zachary Chandler on 1/26/20.
//  Copyright © 2020 Routematch Software, Inc. All rights reserved.
//

import Foundation
import UIKit

typealias Examples = [Example]

struct Example {
    var title: String
    var type: ExampleType
}

extension Example {
    static var examples: Examples {
        let allIndexes = Example(title: "All Indexes", type: .allIndexes)
        let cluster = Example(title: "Clustering", type: .cluster)
        let core = Example(title: "Core Functions", type: .core)
        let point = Example(title: "Point Layer", type: .pointLayer)
        let polygon = Example(title: "Polygon Layer", type: .polygonLayer)
        let analysis = Example(title: "Analysis", type: .analysis)
        
        return [core, allIndexes, cluster, point, polygon, analysis]
    }
    
    enum ExampleType {
        case cluster
        case allIndexes
        case pointLayer
        case polygonLayer
        case analysis
        case core
    }
    
    var viewController: ExampleViewController {
        var vc: ExampleViewController!
        
        switch type {
        case .allIndexes:
            vc = PolygonViewController()
        case .cluster:
            vc = ClusterViewController()
        case .pointLayer:
            vc = PointLayerViewController()
        case .polygonLayer:
            vc = CoreFunctionsViewController()
        case .analysis:
            vc = CoreFunctionsViewController()
        case .core:
            vc = CoreFunctionsViewController()
        }
        
        vc.example = self
        
        return vc
    }
    
//    var geoJson: 
}

