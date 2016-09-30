//
//  MapViewController.swift
//  GeekBus
//
//  Created by Luis Mariano Arobes on 29/09/16.
//  Copyright © 2016 Luis Mariano Arobes. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var topView: UIView!
    
    @IBOutlet weak var panelView: UIView!
    @IBOutlet weak var panelViewTopConstraint: NSLayoutConstraint!
    var panelViewController: MapPanelViewController?
    var panelViewGoingUp = false
    
    lazy var panGestureRecognizer: UIPanGestureRecognizer = {
        let gr = UIPanGestureRecognizer(target: self, action: #selector(panGesture(gestureRecognizer:)))
        self.panelView.addGestureRecognizer(gr)
        return gr
    }()
    
    var didSetAnnotationsInMap = false
    
    var ruta: Ruta!
    
    var originalPanelPosition: CGFloat = 0
    var lastPoint: CGPoint = CGPoint.zero
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let ruta = ruta {
            if ruta.stations.count > 0 {
                addAnnotationsOf(stations: ruta.stations)
            }            
        }
        
        setupViews()
        
        showNavBar()
    }
    
    func setupViews() {
        _ = panGestureRecognizer        
        panelView.addShadow()
        
        originalPanelPosition = panelViewTopConstraint.constant                
        
        let rutaView = RutaView(frame: CGRect(x: 0.0, y: 0.0, width: 100.0, height: 50.0))
        rutaView.ruta = ruta
        rutaView.tintColor = UIColor.white
        
        let busView = rutaView.busView
        busView?.frame = CGRect(x: 0.0, y: 0.0, width: 50.0, height: 50.0)
        navigationItem.titleView = busView
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "panelSegue" {
            if let destViewController = segue.destination as? MapPanelViewController {
                panelViewController = destViewController
                panelViewController?.topViewController = self
                
                if let ruta = ruta {
                    print("adding single station")
                    
                    if ruta.stations.count > 0 {
                        panelViewController?.addStationsToTableViewFrom(ruta: ruta)
                    }
                    else {
                        panelViewController?.getStationsOfRuta(ruta: ruta)                        
                    }
                    
                }
            }
        }
    }
    
    //MARK: - Methods
    func openMapsWith(coordinate: CLLocationCoordinate2D, name: String) {
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = name
        
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking])
    }
    
}

//MARK: - Actions
extension MapViewController {
    
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

//MARK: - Gestures
extension MapViewController {
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

//MARK: - Map Methods
extension MapViewController: MKMapViewDelegate {
    
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
        
        if !didSetAnnotationsInMap {
            didSetAnnotationsInMap = false
            //mapView.fitMapViewToAnnotationList()
            mapView.showAnnotations(mapView.annotations, animated: false)
        }
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        if !didSetAnnotationsInMap {
            didSetAnnotationsInMap = true
            mapView.fitMapViewToAnnotationList()
        }
    }
    
    func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
        /*if fullyRendered && !didSetAnnotationsInMap {
            didSetAnnotationsInMap = true
            //mapView.fitMapViewToAnnotationList()
            mapView.showAnnotations(mapView.annotations, animated: false)
        }*/
    }
    
}
