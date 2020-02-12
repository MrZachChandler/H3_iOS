//
//  Style.swift
//  H3_Test
//
//  Created by Zachary Chandler on 1/26/20.
//  Copyright © 2020 Routematch Software, Inc. All rights reserved.
//

import Foundation
import UIKit
import Mapbox

final class Style {
    fileprivate static var _shared: Style!
    
    var preference: Preference = .dark
    
    fileprivate init () {
        
    }
    
    func updateUIPreference() {
        guard let vc = UIApplication.getTopViewController() else { return }
                
        if vc.traitCollection.userInterfaceStyle == .dark {
            preference =  .dark
        } else {
            preference = .light
        }
        
        //post ui updatee notification
    }
    
    enum Preference {
        case dark
        case light
        
        var textColor: UIColor {
            switch self {
            case .dark:
                return .lightGray
            case .light:
                return .black
            }
        }
        
        var backgroundColor: UIColor {
            switch self {
            case .dark:
                return .black
            case .light:
                return .white
            }
        }
        
        var mapStyle: URL {
            switch self {
            case .dark:
                return MGLStyle.darkStyleURL
            case .light:
                return MGLStyle.lightStyleURL
            }
        }
    }
}

extension Style {
    static var shared: Style {
        if let shared = _shared {
            return shared
        }
        
        _shared = Style()
        return _shared
    }
}
