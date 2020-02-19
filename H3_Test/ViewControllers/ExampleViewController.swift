//
//  ExampleViewController.swift
//  H3_Test
//
//  Created by Zachary Chandler on 1/26/20.
//  Copyright © 2020 Zachary Chandler All rights reserved.
//

import Foundation
import Mapbox
import SnapKit
import Eureka
import Turf
import H3Swift

class ExampleViewController: FormViewController, H3MapDelegate {
    var hexLayers: [MGLStyleLayer] = []
    var example: Example! { didSet { title = example.title }}
    var resolution: Int32 = 4
    var mapView: MGLMapView!
    var activity: UIActivityIndicatorView?
    var actView: UIView?
    var isLoading = false
        
    var curLocation: CLLocation { return CLLocation(latitude: 33.789, longitude: -84.384) }

    override var shouldAutorotate: Bool { return true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { return .landscape }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addMapView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        mapView.snp.makeConstraints { make in
            make.top.bottom.right.equalToSuperview()
            make.width.equalTo(view.frame.width - (view.frame.width / 3))
        }
        
        tableView.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.right.equalTo(mapView.snp.left)
        }
    }

    func addMapView() {
        mapView = MGLMapView(frame: view.bounds)
        mapView.delegate = self
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.showsUserHeadingIndicator = true
        mapView.styleURL = userInterfaceStyle.mapStyle
        
        view.addSubview(mapView)
    }

    func startLoading() {
        guard activity == nil else { return }
    
        let activity = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        let actView = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        
        actView.backgroundColor = userInterfaceStyle.backgroundColor
        actView.alpha = 0
        actView.addSubview(activity)
        
        view.addSubview(actView)
        view.bringSubviewToFront(actView)
        
        activity.snp.makeConstraints { $0.center.equalTo(actView.snp.center) }
        actView.snp.makeConstraints { $0.center.equalToSuperview() }
        
        UIView.animate(withDuration: 2) { actView.alpha = 1 }
        
        self.activity = activity
        self.actView = actView
        
        activity.startAnimating()
    }
    
    func stopLoading() {
        UIView.animate(withDuration: 2) { [weak self] in self?.actView?.alpha = 0 }
        
        isLoading = false
        
        activity?.stopAnimating()
        activity?.removeFromSuperview()
        activity = nil
        
        actView?.removeFromSuperview()
        actView = nil
    }
}
extension ExampleViewController: MGLMapViewDelegate {
    func mapViewDidFinishLoadingMap(_ mapView: MGLMapView) {
        // Wait for the map to load before initiating the first camera movement.
        animateTo(location: curLocation)
    }
    
    func mapViewRegionIsChanging(_ mapView: MGLMapView) {
        print("Zoom Level: \(mapView.zoomLevel)")
    }
    
    func mapViewDidBecomeIdle(_ mapView: MGLMapView) {
        print("mapViewDidBecomeIdle - Zoom Level: \(mapView.zoomLevel)")
    }
}

extension ExampleViewController {
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
