//
//  LandingViewController.swift
//  H3_Test
//
//  Created by Zachary Chandler on 1/26/20.
//  Copyright © 2020 Routematch Software, Inc. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class LandingViewController: UITableViewController {
    let examples = Example.examples
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        title = "Examples"
        Style.shared.updateUIPreference()
        tableView.register(ExampleTableViewCell.self, forCellReuseIdentifier: "Example")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        Style.shared.updateUIPreference()
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
        navigationController?.pushViewController(examples[indexPath.row].viewController, animated: true)
    }
}

extension UIViewController {
    func showWarning(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            UIApplication.getTopViewController()?.present(alert, animated: true, completion: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                alert.dismiss(animated: true, completion: nil)
            }
        }
    }
}
