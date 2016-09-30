//
//  ViewController.swift
//  GeekBus
//
//  Created by Luis Mariano Arobes on 26/09/16.
//  Copyright © 2016 Luis Mariano Arobes. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController {
    
    //MARK: - Outlets
    @IBOutlet weak var panelViewTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var panelView: UIView!
    
    @IBOutlet weak var topView: UIView!
        
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var userLocationButton: UIButton! {
        didSet {
            userLocationButton.addShadow(opacity: 0.3, radius: 3)
        }
    }
    
    
    @IBOutlet weak var markerCurrentLocation: UIImageView! {
        didSet {
            markerCurrentLocation.addShadow()
        }
    }
    
    @IBOutlet weak var markerCurrentLocationYConstraint: NSLayoutConstraint!
    
    //MARK: - Variables
    //var originalPanelAlpha: CGFloat = 0
    var originalPanelPosition: CGFloat = 0
    var lastPoint: CGPoint = CGPoint.zero
    var panelViewGoingUp = false
    
    var shouldShowNavBar = false    
    var shouldHideNavBarWhenDisappearing = false
    
    var station: Station?
    
    var locationManager: CLLocationManager!
    var didCenteredOnUserLocation = false
    var isUpdatingLocation = false
    
    var mapChangedFromUserInteraction = false
    var followingUserLocation = true {
        didSet {
            userLocationButton.isSelected = followingUserLocation
        }
    }
    
    var mapShowingAllAnnotations = false
    
    lazy var panGestureRecognizer: UIPanGestureRecognizer = {
        let gr = UIPanGestureRecognizer(target: self, action: #selector(panGesture(gestureRecognizer:)))
        self.panelView.addGestureRecognizer(gr)
        return gr
    }()
    
    weak var panelViewController: PanelViewController?
    
    //MARK: - Override Methods
    override func viewDidLoad() {
        super.viewDidLoad()        
        
        _ = panGestureRecognizer
        originalPanelPosition = panelViewTopConstraint.constant
        //originalPanelAlpha = panelView.alpha
        
        mapView.delegate = self
        
        if let _ = station {
            markerCurrentLocation.isHidden = true
            followingUserLocation = false
        }
        else {
            markerCurrentLocation.isHidden = false
            followingUserLocation = true
            setupLocationManager()
        }
        
        panelView.addShadow()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if navigationController?.viewControllers.count == 1 {
            hideNavBar()
        }
        else {
            showNavBar()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "panelSegue" {
            if let destViewController = segue.destination as? PanelViewController {
                panelViewController = destViewController
                panelViewController?.topViewController = self
                
                if let station = station {
                    print("adding single station")
                    panelViewController?.addSingleStation(station)
                }
            }
        }
    }
    
    //MARK: - Methods
    func openMapsWith(coordinate: CLLocationCoordinate2D, name: String) {
        
        var mapItem: MKMapItem!
        
        if let station = station {
            let coordinateStation = CLLocationCoordinate2D(latitude: station.latitud, longitude: station.longitud)
            mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinateStation))
            mapItem.name = station.nombre
        }
        else {
            mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
            mapItem.name = name
        }
        
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking])
    }
}

//MARK: - Gestures
extension ViewController {
    func panGesture(gestureRecognizer: UIPanGestureRecognizer) {
        let point = gestureRecognizer.location(in: self.view)
        
        var screenHeight = view.frame.size.height - UIApplication.shared.statusBarFrame.size.height
        
        if let navigationBar = navigationController?.navigationBar {
            if !navigationBar.isHidden {
                screenHeight -= (navigationBar.frame.size.height + 10)
            }
        }
        
        let centerRatio = (-panelViewTopConstraint.constant + originalPanelPosition) / (screenHeight + originalPanelPosition)
        
        print("lastPoint y = ", lastPoint.y)
        print("point y = ", point.y)
        
        if lastPoint.y > point.y {
            //going up
            panelViewGoingUp = true
            print("going up")
        }
        else if lastPoint.y < point.y {
            //going down
            panelViewGoingUp = false
            print("going down")
        }
        
        let centerRatioLimit: CGFloat = panelViewGoingUp ? 0.15 : 0.85
        
        switch gestureRecognizer.state {
        case .changed:
            
            let yDelta = point.y - lastPoint.y
            var newConstant = panelViewTopConstraint.constant + yDelta
            newConstant = newConstant > originalPanelPosition ? originalPanelPosition : newConstant
            newConstant = newConstant < -screenHeight ? -screenHeight : newConstant
            panelViewTopConstraint.constant = newConstant
            
            print("centerRatio = ", centerRatio)
            print("centerRadioLimit = ", centerRatioLimit)
            
        case .ended:
            
            self.panelViewTopConstraint.constant = centerRatio < centerRatioLimit ? self.originalPanelPosition : -screenHeight
            self.panelViewController?.tableview.isScrollEnabled = !(centerRatio < centerRatioLimit)
            
            UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: [.curveEaseInOut], animations: {
                self.view.layoutIfNeeded()
                
                }, completion: nil)
            
        default:
            break
        }
        
        lastPoint = point
    }
}

//MARK: - Actions 
extension ViewController {
    @IBAction func userLocationButtonAction(_ sender: UIButton) {
        followingUserLocation = !followingUserLocation
        moveMapToLocation(center: mapView.userLocation.coordinate)
    }
    
    func walkindDirectionsButtonAction(_ sender: UIButton) {
        if sender.tag != -1 && sender.tag < mapView.annotations.count {
            let annotation = mapView.annotations[sender.tag]
            if let name = annotation.title {
                openMapsWith(coordinate: annotation.coordinate, name: name ?? "")
            }
            else {
                openMapsWith(coordinate: annotation.coordinate, name: "")
            }
            
        }
    }
}

//MARK: - Animations
extension ViewController {
    
    func animateMarkerDrop(completion: ((Bool) -> ())? = nil) {
        markerCurrentLocation.alpha = 1.0
        markerCurrentLocationYConstraint.constant += 10
        
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.3, initialSpringVelocity: 0.5, options: [.curveEaseInOut], animations: {
            self.view.layoutIfNeeded()
            
            }, completion: completion)
    }
    
    func animateMarkerDragging(completion: ((Bool) -> ())? = nil) {
        markerCurrentLocation.alpha = 0.4
        markerCurrentLocationYConstraint.constant -= 10
        
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.3, initialSpringVelocity: 0.5, options: [.curveEaseInOut], animations: {
            self.view.layoutIfNeeded()
            
            }, completion: completion)
    }
    
}

//MARK: - MapKit and CoreLocation methods
extension ViewController: CLLocationManagerDelegate, MKMapViewDelegate {
    
    func setupLocationManager() {
        print("setup")
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        locationManager.requestWhenInUseAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.desiredAccuracy = kCLLocationAccuracyBest
            manager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //print("didUpdate")
        
        /*
        if followingUserLocation {
            if let location = locations.last {
                if !isUpdatingLocation {
                    isUpdatingLocation = true
                    moveMapToLocation(location: location)
                    isUpdatingLocation = false
                }
                didCenteredOnUserLocation = true
            }
        }*/
    }
    
    func moveMapToLocation(location: CLLocation, animated: Bool = true) {
        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        moveMapToLocation(center: center, animated: animated)
    }
    
    func moveMapToLocation(center: CLLocationCoordinate2D, animated: Bool = true) {
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.007, longitudeDelta: 0.007))
        mapView.setRegion(region, animated: animated)
    }
    
    private func mapViewRegionDidChangeFromUserInteraction() -> Bool {
        let view = mapView.subviews[0]
        //  Look through gesture recognizers to determine whether this region change is from user interaction
        if let gestureRecognizers = view.gestureRecognizers {
            for recognizer in gestureRecognizers {
                if( recognizer.state == UIGestureRecognizerState.began || recognizer.state == UIGestureRecognizerState.ended ) {
                    return true
                }
            }
        }
        return false
    }
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        
        if station == nil {
            animateMarkerDragging()
        }
        
        mapChangedFromUserInteraction = mapViewRegionDidChangeFromUserInteraction()
        if mapChangedFromUserInteraction {
            followingUserLocation = false
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        if station == nil {
            animateMarkerDrop { (success) in
                let centre = mapView.centerCoordinate
                //print("centre = ", centre)
                self.panelViewController?.getStationsNear(latitude: centre.latitude, longitude: centre.longitude)
            }
        }
        
        if mapChangedFromUserInteraction {
            followingUserLocation = false
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !(annotation is MKUserLocation) else {
            return nil
        }
        
        let annotationIdentifier = "AnnotationIdentifier"
        
        var annotationView: MKAnnotationView?
        
        if let dequeuedAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier) {
            annotationView = dequeuedAnnotationView
            
            annotationView?.annotation = annotation
        }
        else {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
        }
        
        if let annotationView = annotationView {
            
            annotationView.canShowCallout = true
            annotationView.image = #imageLiteral(resourceName: "stopMarker")
            
            let button = UIButton(type: .detailDisclosure)
            
            let walkingImage = #imageLiteral(resourceName: "walkingIcon")
            button.setImage(walkingImage, for: .normal)
            button.tintColor = UIColor.black
            
            //Saves the index of the annotation
            button.tag = self.mapView.annotations.index(where: { $0 === annotation }) ?? -1
            
            button.addTarget(self, action: #selector(walkindDirectionsButtonAction(_:)), for: .touchUpInside)
            
            annotationView.rightCalloutAccessoryView = button
        }
        
        return annotationView
    }
    
    func addAnnotationsOf(stations: [Station]) {
        if mapView.delegate == nil {
            mapView.delegate = self
        }
        
        mapView.removeAnnotations(mapView.annotations)
        
        for station in stations {
            let annotation = MKPointAnnotation()
            
            annotation.title = station.nombre
            
            let location = CLLocationCoordinate2D(latitude: station.latitud, longitude: station.longitud)
            annotation.coordinate = location
            
            mapView.addAnnotation(annotation)            
        }
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        if let _ = station {
            if !mapShowingAllAnnotations {
                //mapView.showAnnotations(mapView.annotations, animated: true)
                
                mapView.fitMapViewToAnnotationList()
                mapShowingAllAnnotations = true
            }
        }
        else {
            if followingUserLocation {
                moveMapToLocation(center: userLocation.coordinate)
            }
        }
    }
}
