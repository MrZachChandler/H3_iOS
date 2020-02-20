//
//  Extensions.swift
//  H3_Test
//
//  Created by Zachary Chandler on 2/17/20.
//  Copyright © 2020 Zachary Chandler. All rights reserved.
//

import Foundation
import UIKit
import Mapbox

typealias Colors = [UIColor]
typealias ColorRange = [Double: UIColor]

extension UIFont {
    func withTraits(traits:UIFontDescriptor.SymbolicTraits) -> UIFont {
        let descriptor = fontDescriptor.withSymbolicTraits(traits)
        return UIFont(descriptor: descriptor!, size: 0) //size 0 means keep the size as it is
    }

    func bold() -> UIFont {
        return withTraits(traits: .traitBold)
    }

    func italic() -> UIFont {
        return withTraits(traits: .traitItalic)
    }
}

extension UINavigationController {

    override open var shouldAutorotate: Bool {
        get {
            if let visibleVC = visibleViewController {
                return visibleVC.shouldAutorotate
            }
            return super.shouldAutorotate
        }
    }

    override open var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation{
        get {
            if let visibleVC = visibleViewController {
                return visibleVC.preferredInterfaceOrientationForPresentation
            }
            return super.preferredInterfaceOrientationForPresentation
        }
    }

    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask{
        get {
            if let visibleVC = visibleViewController {
                return visibleVC.supportedInterfaceOrientations
            }
            return super.supportedInterfaceOrientations
        }
    }
}

extension UIViewController {
    func showWarning(title: String, message: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            self.present(alert, animated: true, completion: nil)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { alert.dismiss(animated: true, completion: nil) }
        }
    }
    
    func showMemoryWarning() { showWarning(title: "Memory Warning", message: "Choose higher resolution") }
}

extension UITraitEnvironment {
    var userInterfaceStyle: UIUserInterfaceStyle { return traitCollection.userInterfaceStyle }
}

extension UIUserInterfaceStyle {
    var textColor: UIColor {
        switch self {
        case .dark:
            return .lightGray
        case .light:
            return .black
        default:
            return .lightGray
        }
    }
    
    var activityViewColor: UIColor {
         switch self {
         case .dark:
             return .white
         case .light:
             return .black
         default:
             return .black
        }
    }
 
    var backgroundColor: UIColor {
         switch self {
         case .dark:
             return .black
         case .light:
             return .white
         default:
             return .white
        }
    }
 
    var mapStyle: URL {
        switch self {
        case .dark:
            return MGLStyle.darkStyleURL
        case .light:
            return MGLStyle.lightStyleURL
        default:
            return MGLStyle.lightStyleURL
        }
    }
    
    fileprivate var _tinyColors: Colors { return [#colorLiteral(red: 0.9979701638, green: 0.9997151494, blue: 0.8536984324, alpha: 1), #colorLiteral(red: 0.3144622147, green: 0.728943646, blue: 0.7659309506, alpha: 1), #colorLiteral(red: 0.1020374969, green: 0.2753289044, blue: 0.5405613184, alpha: 1)] }
    fileprivate var _colors : Colors { return [#colorLiteral(red: 0.9979701638, green: 0.9997151494, blue: 0.8536984324, alpha: 1), #colorLiteral(red: 0.7931016684, green: 0.9181226492, blue: 0.7061831355, alpha: 1) , #colorLiteral(red: 0.5612027049, green: 0.8272815347, blue: 0.7307203412, alpha: 1), #colorLiteral(red: 0.3134610653, green: 0.7285520434, blue: 0.7656949162, alpha: 1), #colorLiteral(red: 0.2001188099, green: 0.6143624187, blue: 0.7579681277, alpha: 1), #colorLiteral(red: 0.1654939055, green: 0.496352613, blue: 0.7168431878, alpha: 1), #colorLiteral(red: 0.1028115973, green: 0.2763790488, blue: 0.543992579, alpha: 1), #colorLiteral(red: 0.1020374969, green: 0.2753289044, blue: 0.5405613184, alpha: 1), #colorLiteral(red: 0.066839315, green: 0.1823011935, blue: 0.4287363291, alpha: 1), #colorLiteral(red: 0.02621367574, green: 0.09617900103, blue: 0.3011858463, alpha: 1), #colorLiteral(red: 0.004857238848, green: 0, blue: 0.1536510587, alpha: 1)] }
    
    /// Defatult Hexagon Colors
    var darkColor: UIColor { return _tinyColors[0]  }
    var lightColor: UIColor { return _tinyColors[0] }
    var medColor: UIColor { return _tinyColors[0]  }

    /// Hexagon Colors
    var colors: Colors { return self == .dark ? _colors.reversed() : _colors }
    var tinyColors : Colors { return self == .dark ? _tinyColors.reversed() : _tinyColors }
    
    /// Distance Span
    var shortRange      : ColorRange { return colors.range(from: 0, to: 1) }
    var medRange        : ColorRange { return colors.range(from: 0, to: 100) }
    var longRange       : ColorRange { return colors.range(from: 0, to: 1000)}
    /// Tiny Color Scale
    var shortRangeTiny  : ColorRange { return tinyColors.range(from: 0, to: 1) }
    var medRangeTiny    : ColorRange { return tinyColors.range(from: 0, to: 100) }
    var longRangeTiny   : ColorRange { return tinyColors.range(from: 0, to: 1000)}
}

extension Colors {
    func range(from finish: Double, to start: Double, reversed: Bool = false) -> ColorRange {
        guard start > finish else { return range(from: 0, to: 1) }
         
         let colors = reversed ? self.reversed() : self
         let step = (start - finish) / 10
         
         var range : ColorRange = [:]
         var index = finish
         var i = 0
         
         colors.forEach {
             range[index] = $0
             i += 1
             index += step
         }
         
         return range
    }
}
