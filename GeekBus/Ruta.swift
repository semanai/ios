//
//  Ruta.swift
//  GeekBus
//
//  Created by Luis Mariano Arobes on 27/09/16.
//  Copyright © 2016 Luis Mariano Arobes. All rights reserved.
//

import Foundation

class Ruta: NSObject {
    
    var id: Int!
    var nombre: String!
    var numero: String!
    var timeLeft: Double?
    var stations: [Station]
    
    init(id: Int! = 0, nombre: String!, numero: String!, timeLeft: Double? = 0.0, stations: [Station] = [Station]() ) {
        self.id = id
        self.nombre = nombre
        self.numero = numero
        self.timeLeft = timeLeft
        self.stations = stations
    }
    
    
}
