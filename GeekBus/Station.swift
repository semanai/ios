//
//  Station.swift
//  GeekBus
//
//  Created by Luis Mariano Arobes on 27/09/16.
//  Copyright © 2016 Luis Mariano Arobes. All rights reserved.
//

import Foundation

class Station: NSObject {
    
    var id: Int!
    var nombre: String!
    var latitud: Double!
    var longitud: Double!
    var rutas: [Ruta]?
    var timeToStation: Double!
    
    init(id: Int! = 0, nombre: String!, latitud: Double!, longitud: Double!, rutas: [Ruta]? = nil, timeToStation: Double! = 0.0) {
        self.id = id
        self.latitud = latitud
        self.longitud = longitud
        self.nombre = nombre
        
        if let rutas = rutas {
            self.rutas = rutas
        } else {
            self.rutas = [Ruta]()
        }
        
        self.timeToStation = timeToStation
    }
    
}
