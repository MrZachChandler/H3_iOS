//
//  LandingViewController.swift
//  H3_Test
//
//  Created by Zachary Chandler on 1/26/20.
//  Copyright © 2020 Zachary Chandler All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class LandingViewController: UITableViewController {
    let examples = Example.examples
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { return .all }
    override var shouldAutorotate: Bool { return true }
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Examples"
        navigationController?.navigationBar.prefersLargeTitles = true
        Style.shared.updateUIPreference(traitCollection.userInterfaceStyle)
        tableView.register(ExampleTableViewCell.self, forCellReuseIdentifier: "Example")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        Style.shared.updateUIPreference(traitCollection.userInterfaceStyle)
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return examples.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Example", for: indexPath) as! ExampleTableViewCell
        cell.example = examples[indexPath.row]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let device = UIDevice.current
        if !device.orientation.isLandscape {
            let value = UIInterfaceOrientation.landscapeRight.rawValue
            device.setValue(value, forKey: "orientation")
        }
        let vc = examples[indexPath.row].viewController
        navigationController?.pushViewController(vc, animated: true)
    }
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
}
