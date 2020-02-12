//
//  ExampleTableViewCell.swift
//  H3_Test
//
//  Created by Zachary Chandler on 1/26/20.
//  Copyright © 2020 Routematch Software, Inc. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class ExampleTableViewCell: UITableViewCell {
    var example: Example! { didSet {
            setNeedsLayout()
            layoutIfNeeded()
            setNeedsDisplay()
        }
    }

    lazy var label: UILabel = {
        let label = UILabel(frame: contentView.frame)
        label.font = UIFont.preferredFont(forTextStyle: .headline)
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
