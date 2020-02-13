//
//  ExampleTableViewCell.swift
//  H3_Test
//
//  Created by Zachary Chandler on 1/26/20.
//  Copyright © 2020 Zachary Chandler All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class ExampleTableViewCell: UITableViewCell {
    var example: Example! {
        didSet {
            setNeedsLayout()
            layoutIfNeeded()
            setNeedsDisplay()
        }
    }

    lazy var label: UILabel = {
        let label = UILabel(frame: contentView.frame)
        label.font = UIFont.preferredFont(forTextStyle: .headline).bold()
        label.textColor = Style.shared.preference.textColor
        label.backgroundColor = Style.shared.preference.backgroundColor
        label.textAlignment = .left

        contentView.addSubview(label)
        
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }
        
        return label
    }()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        label.text = example.title
        label.textColor = Style.shared.preference.textColor
        label.backgroundColor = Style.shared.preference.backgroundColor
        contentView.backgroundColor = Style.shared.preference.backgroundColor
    }
}

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
