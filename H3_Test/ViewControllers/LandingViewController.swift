//
//  LandingViewController.swift
//  H3_Test
//
//  Created by Zachary Chandler on 1/26/20.
//  Copyright © 2020 Zachary Chandler All rights reserved.
//

import UIKit

class LandingViewController: UITableViewController {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { return .all }
    override var shouldAutorotate: Bool { return true }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Examples"
        navigationController?.navigationBar.prefersLargeTitles = true
        tableView.register(ExampleTableViewCell.self, forCellReuseIdentifier: "Example")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Example.examples.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Example", for: indexPath) as! ExampleTableViewCell
        cell.example = Example.examples[indexPath.row]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let device = UIDevice.current
        let vc = Example.examples[indexPath.row].viewController

        if !device.orientation.isLandscape {
            let value = UIInterfaceOrientation.landscapeRight.rawValue
            device.setValue(value, forKey: "orientation")
        }

        navigationController?.pushViewController(vc, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
}
