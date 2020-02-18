//
//  Style.swift
//  H3_Test
//
//  Created by Zachary Chandler on 1/26/20.
//  Copyright © 2020 Zachary Chandler All rights reserved.
//

import Foundation
import UIKit
import Mapbox

typealias ColorRange = [Double: UIColor]

final class Style {
    fileprivate static var _shared: Style!
    fileprivate init () { }

    static var shared: Style {
        if let shared = _shared {
            return shared
        }
        
        _shared = Style()
        return _shared
    }
    
    var preference: Preference = .dark

    func updateUIPreference(_ style : UIUserInterfaceStyle) {
        if style == .dark {
            preference =  .dark
        } else {
            preference = .light
        }
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
        
        private var rangeColorSet: [UIColor] {
            switch self {
            case .light:
                return [#colorLiteral(red: 0.9979701638, green: 0.9997151494, blue: 0.8536984324, alpha: 1), #colorLiteral(red: 0.7931016684, green: 0.9181226492, blue: 0.7061831355, alpha: 1) , #colorLiteral(red: 0.5612027049, green: 0.8272815347, blue: 0.7307203412, alpha: 1), #colorLiteral(red: 0.3134610653, green: 0.7285520434, blue: 0.7656949162, alpha: 1), #colorLiteral(red: 0.2001188099, green: 0.6143624187, blue: 0.7579681277, alpha: 1), #colorLiteral(red: 0.1654939055, green: 0.496352613, blue: 0.7168431878, alpha: 1), #colorLiteral(red: 0.1028115973, green: 0.2763790488, blue: 0.543992579, alpha: 1), #colorLiteral(red: 0.1020374969, green: 0.2753289044, blue: 0.5405613184, alpha: 1), #colorLiteral(red: 0.066839315, green: 0.1823011935, blue: 0.4287363291, alpha: 1), #colorLiteral(red: 0.02621367574, green: 0.09617900103, blue: 0.3011858463, alpha: 1), #colorLiteral(red: 0.004857238848, green: 0, blue: 0.1536510587, alpha: 1)]
            case .dark:
                return [#colorLiteral(red: 0.9979701638, green: 0.9997151494, blue: 0.8536984324, alpha: 1), #colorLiteral(red: 0.7931016684, green: 0.9181226492, blue: 0.7061831355, alpha: 1) , #colorLiteral(red: 0.5612027049, green: 0.8272815347, blue: 0.7307203412, alpha: 1), #colorLiteral(red: 0.3134610653, green: 0.7285520434, blue: 0.7656949162, alpha: 1), #colorLiteral(red: 0.2001188099, green: 0.6143624187, blue: 0.7579681277, alpha: 1), #colorLiteral(red: 0.1654939055, green: 0.496352613, blue: 0.7168431878, alpha: 1), #colorLiteral(red: 0.1028115973, green: 0.2763790488, blue: 0.543992579, alpha: 1), #colorLiteral(red: 0.1020374969, green: 0.2753289044, blue: 0.5405613184, alpha: 1), #colorLiteral(red: 0.066839315, green: 0.1823011935, blue: 0.4287363291, alpha: 1), #colorLiteral(red: 0.02621367574, green: 0.09617900103, blue: 0.3011858463, alpha: 1), #colorLiteral(red: 0.004857238848, green: 0, blue: 0.1536510587, alpha: 1)].reversed()
            }
        }
        
        var reallyLongRange: ColorRange { return colorRange(from: 0, to: 1000000) }
        var kindaLongRange: ColorRange { return colorRange(from: 0, to: 100000) }
        var longRange: ColorRange { return colorRange(from: 0, to: 1000) }
        var medRange: ColorRange { return colorRange(from: 0, to: 100) }
        var shortRange: ColorRange { return colorRange(from: 0, to: 1) }
        var tinyRange: ColorRange { return [0: #colorLiteral(red: 0.9979701638, green: 0.9997151494, blue: 0.8536984324, alpha: 1), 0.5: #colorLiteral(red: 0.3144622147, green: 0.728943646, blue: 0.7659309506, alpha: 1), 1: #colorLiteral(red: 0.1020374969, green: 0.2753289044, blue: 0.5405613184, alpha: 1)] }
        
        func colorRange(from finish: Double, to start: Double) -> ColorRange {
            guard start > finish else { return shortRange }
            
            let colors = rangeColorSet
            let step = (start - finish) / 10
            
            var range : ColorRange = [:]
            var index = finish
            var i = 0
            
            while i <= 10 {
                range[index] = colors[i]
                i += 1
                index += step
            }
            
            return range
        }
    }
}
