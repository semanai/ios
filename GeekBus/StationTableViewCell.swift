//
//  StationTableViewCell.swift
//  GeekBus
//
//  Created by Luis Mariano Arobes on 27/09/16.
//  Copyright © 2016 Luis Mariano Arobes. All rights reserved.
//

import UIKit

class StationTableViewCell: UITableViewCell {

    @IBOutlet private weak var stationNameLabel: UILabel!
    @IBOutlet private weak var infoLabel: UILabel!
    
    @IBOutlet weak var stationView: UIView!
    @IBOutlet weak var stackView: UIStackView! {
        didSet {
            stackView.isUserInteractionEnabled = true
        }
    }
    
    public var stationName: String! {
        didSet {
            stationNameLabel.text = stationName
        }
    }
    
    var station: Station! {
        didSet {
            setupViewBasedOn(station: station)
        }
    }
    
    public var tapRutaAction: ((_ ruta: Ruta) -> ())?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.backgroundColor = UIColor.clear.withAlphaComponent(0.0)
        backgroundColor = UIColor.white.withAlphaComponent(1.0)
        
        layoutMargins = .zero
        separatorInset = .zero
        //selectionStyle = .none
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    private func getNombreRutas() -> String {
        var nombreRutas = ""
        if let rutas = station.rutas {
            for i  in 0 ..< rutas.count  {
                guard let rutaNumber = rutas[i].numero else {
                    continue
                }
                
                nombreRutas.append("R-\(rutaNumber)")
                if i < rutas.count - 1 {
                    nombreRutas.append(", ")
                }
            }
        }
        
        return nombreRutas
    }
    
    private func setupViewBasedOn(station: Station!) {
        stationName = station.nombre
        
        infoLabel.text = "\(Int(station.timeToStation)) \(NSLocalizedString("min walk", comment: "")) · \(getNombreRutas())"
        
        if let rutas  = station.rutas {
            setupRutasViews(rutas: rutas)
        }
        
        layoutIfNeeded()
        layoutSubviews()
    }
    
    private func setupRutasViews(rutas: [Ruta]!) {
        removeViewsInStackView()
        
        for ruta in rutas {
            let rutaView = RutaView(frame: stackView.frame)
            //rutaView.heightAnchor.constraint(equalToConstant: 42).isActive = true
            rutaView.ruta = ruta            
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(rutaTappedAction(gesture:)))
            rutaView.addGestureRecognizer(tap)
            
            stackView.addArrangedSubview(rutaView)
        }
    }
    
    private func removeViewsInStackView() {
        let stackViewArrangedSubviews = stackView.arrangedSubviews
        
        for view in stackViewArrangedSubviews {
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        
    }
    
    func rutaTappedAction(gesture: UITapGestureRecognizer) {
        gesture.view?.simuateTouch()
        
        guard let rutaView = gesture.view as? RutaView,
            let tapRutaAction = tapRutaAction else {
                return
        }
        
        tapRutaAction(rutaView.ruta)
    }
}
