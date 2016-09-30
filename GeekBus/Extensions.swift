//
//  Extensions.swift
//  GeekBus
//
//  Created by Luis Mariano Arobes on 27/09/16.
//  Copyright © 2016 Luis Mariano Arobes. All rights reserved.
//

import Foundation
import UIKit
import MapKit

extension UIView {
    
    func roundView(radius: CGFloat = 3.0) {
        clipsToBounds = true
        layer.cornerRadius = radius
    }
    
    func addShadow(color: UIColor = UIColor.black, opacity: Float = 0.5, offset: CGSize = CGSize.zero, radius: CGFloat = 5) {
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = opacity
        layer.shadowOffset = offset
        layer.shadowRadius = 10
    }
    
    func simuateTouch(initialAlpha: CGFloat! = 0.0, finalAlpha: CGFloat! = 1.0) {
        let oldColor = backgroundColor
        
        backgroundColor = UIColor.lightGray.withAlphaComponent(0.2)
        
        UIView.animate(withDuration: 0.05, animations: {
            self.backgroundColor = UIColor.lightGray.withAlphaComponent(initialAlpha)
            //self.alpha = initialAlpha
            
        }) { (success) in
                
                UIView.animate(withDuration: 0.05, animations: {
                    
                    self.backgroundColor = UIColor.lightGray.withAlphaComponent(finalAlpha)
                    //self.alpha = finalAlpha
                    
                    }, completion: { (success) in
                        
                        self.backgroundColor = oldColor
                        
                })
        }
    }
}

public extension UIAlertController {
    
    public class func showSimpleAlert(title: String, message: String, inController: UIViewController, actionBlock: (() -> ())?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (_) in
            actionBlock?()
        }))
        
        inController.present(alert, animated: true, completion: nil)
    }
    
    public class func showSimpleUnknownErrorAlertInController(controller: UIViewController, actionBlock: ( () -> () )? = nil) {
        showSimpleAlert(title: NSLocalizedString("Error", comment: ""),
                        message: NSLocalizedString("Something went wrong, please try again later", comment: ""),
                        inController: controller, actionBlock: actionBlock)
    }
    
    
    public class func presentAlertWithTextField(inViewController viewController: UIViewController, withTitle title: String, message: String, confirmActionTitle: String, cancelActionTitle: String, textFieldPlaceHolderText: String, confirmAction: ( (_ textString: String?) -> () )?, cancelAction: ( () -> () )? = nil) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: confirmActionTitle, style: .default) { (_) in
            guard let textFields = alert.textFields,
                let confirmAction = confirmAction else {
                    return
            }
            
            let textField = textFields[0]
            confirmAction(textField.text)
        }
        
        let cancelAction = UIAlertAction(title: cancelActionTitle, style: .cancel) { (_) in
            guard let cancelAction = cancelAction else {
                return
            }
            
            cancelAction()
        }
        
        alert.addTextField { (textField) in
            textField.placeholder = textFieldPlaceHolderText
            textField.isSecureTextEntry = true
        }
        
        alert.addAction(confirmAction)
        alert.addAction(cancelAction)
        viewController.present(alert, animated: true, completion: nil)
    }
}

extension UIViewController {
    func hideNavBar() {
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    func showNavBar() {
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
}

extension MKMapView {
    
    func fitMapViewToAnnotationList() {
        let mapEdgePadding = UIEdgeInsets(top: 100, left: 100, bottom: 100, right: 100)
        
        var zoomRect: MKMapRect = MKMapRectNull
        
        for index in 0 ..< self.annotations.count {
            let annotation = self.annotations[index]
            let aPoint: MKMapPoint = MKMapPointForCoordinate(annotation.coordinate)
            let rect: MKMapRect = MKMapRectMake(aPoint.x, aPoint.y, 0.1, 0.1)
            
            if MKMapRectIsNull(zoomRect) {
                zoomRect = rect
            } else {
                zoomRect = MKMapRectUnion(zoomRect, rect)
            }            
        }
        
        self.setVisibleMapRect(zoomRect, edgePadding: mapEdgePadding, animated: false)
    }
}


