//
//  LocationPickerVC.swift
//  Chat_App
//
//  Created by sa3doola on 9/28/20.
//  Copyright © 2020 saad sherif. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

final class LocationPickerVC: UIViewController {
    
    public var completion: ((CLLocationCoordinate2D) -> Void)?
    private var coordinates: CLLocationCoordinate2D?
    private var isPickable = true
    
    private let map: MKMapView = {
        let map = MKMapView()
        return map
    }()
    
    init(coordinates: CLLocationCoordinate2D?) {
        self.coordinates = coordinates
        self.isPickable = coordinates == nil
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        view.addSubview(map)
        if isPickable {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Send",
                                                                style: .done,
                                                                target: self,
                                                                action: #selector(didTapSend))
            
            map.isUserInteractionEnabled = true
            let gesture = UITapGestureRecognizer(target: self,
                                                 action: #selector(didTapMap(_:)))
            gesture.numberOfTapsRequired = 1
            gesture.numberOfTouchesRequired = 1
            map.addGestureRecognizer(gesture)
        }
        else {
            // just showing loaction
            guard let coordinates = self.coordinates else {
                return
            }
            
            let pin  = MKPointAnnotation()
            pin.coordinate = coordinates
            map.addAnnotation(pin)
        }
        
    }
    
    @objc func didTapSend() {
        guard let coordinates = self.coordinates else {
            return
        }
        
        navigationController?.popViewController(animated: true)
        completion?(coordinates)
    }
    
    @objc func didTapMap(_ gesture: UITapGestureRecognizer) {
        let locationInView = gesture.location(in: map)
        let coordinates = map.convert(locationInView, toCoordinateFrom: map)
        self.coordinates = coordinates
        
        for annotation in map.annotations {
            map.removeAnnotation(annotation)
        }
        
        // drop a pin on that location
        let pin  = MKPointAnnotation()
        pin.coordinate = coordinates
        map.addAnnotation(pin)
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        map.frame = view.bounds
    }
}
