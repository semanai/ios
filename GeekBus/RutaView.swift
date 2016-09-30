//
//  RutaView.swift
//  GeekBus
//
//  Created by Luis Mariano Arobes on 27/09/16.
//  Copyright © 2016 Luis Mariano Arobes. All rights reserved.
//

import UIKit

class RutaView: UIView {

    @IBOutlet var contentView: UIView!
    @IBOutlet private weak var rutaLabel: UILabel!
    @IBOutlet private weak var lineView: UIView!
    @IBOutlet private weak var rutaNameLabel: UILabel!
    @IBOutlet private weak var timeLabel: UILabel!
    @IBOutlet public weak var busView: UIView! {
        didSet {
            busView.layer.borderColor = UIColor.lightGray.cgColor
            busView.layer.borderWidth = 0.5
        }
    }
    @IBOutlet weak var busLogo: UIImageView!
    
    public var ruta: Ruta! {
        didSet {
            rutaText = ruta.numero
            rutaName = ruta.nombre
            
            if let timeLeft = ruta.timeLeft {
                timeText = "\(Int(timeLeft)) min"
            }
            else {
                timeText = "-"
            }
            
            layoutSubviews()
        }
    }
    
    public var lineColor: UIColor! {
        didSet {
            lineView.backgroundColor = lineColor
        }
    }
    
    public var rutaText: String! {
        didSet {
            if let rutaText = rutaText {
                rutaLabel.text = "R-\(rutaText)"
            }
        }
    }
    
    public var rutaName: String! {
        didSet {
            rutaNameLabel.text = rutaName
        }
    }
    
    public var timeText: String! {
        didSet {
            timeLabel.text = timeText
        }
    }
    
    override var tintColor: UIColor! {
        didSet {
            rutaNameLabel.textColor = tintColor
            rutaLabel.textColor = tintColor
            
            let logoBus = #imageLiteral(resourceName: "bus")
            let tintedImage = logoBus.withRenderingMode(.alwaysTemplate)
            busLogo.image = tintedImage            
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    private func splitTo20Chars(text: String) -> String {
        let offset = text.characters.count - 20
        let splitIndex = text.index(text.endIndex, offsetBy: -offset)
        
        return "\(text.substring(to: splitIndex))..."
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed("RutaView", owner: self, options: nil)
        
        guard let content = contentView else {
            return
        }
        
        content.isUserInteractionEnabled = true
        content.frame = self.bounds
        content.autoresizingMask = [.flexibleHeight, .flexibleWidth]        
        self.addSubview(content)        
    }
    
    
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
