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
        label.textAlignment = .left
        
        contentView.addSubview(label)
        
        label.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }
        
        return label
    }()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        label.text = example.title
        label.textColor = userInterfaceStyle.textColor
        label.backgroundColor = userInterfaceStyle.backgroundColor
        contentView.backgroundColor = userInterfaceStyle.backgroundColor
    }
}
