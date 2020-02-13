//
//  Examples.swift
//  H3_Test
//
//  Created by Zachary Chandler on 1/26/20.
//  Copyright © 2020 Zachary Chandler All rights reserved.
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
        let point = Example(title: "Point Layer", type: .pointLayer)
        let core = Example(title: "Core Functions", type: .core)
        let polygon = Example(title: "Polygon Layer", type: .polygonLayer)
        let analysis = Example(title: "Analysis", type: .analysis)
        
        return [core, point, polygon, analysis]
    }
    
    enum ExampleType {
        case pointLayer
        case polygonLayer
        case analysis
        case core
    }
    
    var viewController: ExampleViewController {
        var vc: ExampleViewController!
        
        switch type {
        case .pointLayer:
            vc = PointLayerViewController()
        case .polygonLayer:
            vc = PolygonViewController()
        case .analysis:
            vc = ExampleViewController()
        case .core:
            vc = CoreFunctionsViewController()
        }
        
        vc.example = self

        return vc
    }
}

