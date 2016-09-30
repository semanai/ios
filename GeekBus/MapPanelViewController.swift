//
//  MapPanelViewController.swift
//  GeekBus
//
//  Created by Luis Mariano Arobes on 29/09/16.
//  Copyright © 2016 Luis Mariano Arobes. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class MapPanelViewController: UIViewController {

    weak var topViewController: MapViewController?
    
    @IBOutlet weak var pullIndicatorView: UIView! {
        didSet {
            pullIndicatorView.roundView(radius: 4.0)
        }
    }
    
    @IBOutlet weak var tableview: UITableView!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var stationStore = [Station]()
    
    override func viewDidLoad() {
        super.viewDidLoad()        
        
        setupViews()
    }

    func setupViews() {
        view.roundView(radius: 6.0)
        
        tableview.dataSource = self
        tableview.delegate = self
        
        tableview.isScrollEnabled = false
        
        tableview.separatorStyle = .none
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func addStationsToTableViewFrom(ruta: Ruta) {
        stationStore = ruta.stations
        
        if let tableview = tableview {
            tableview.reloadData()
        }
    }        
    
    func getStationsOfRuta(ruta: Ruta) {
        
        if let activityIndicator = activityIndicator {
            activityIndicator.startAnimating()
        }
        
        print("id = ", ruta.id)
        
        Alamofire.request("\(API_URL)/paradas/\(ruta.id ?? 0)/rutas", method: .get).responseJSON { [weak self] (response) in
            
            print("response url = ", response.request)
            
            guard let strongSelf = self else {
                return
            }
            
            print("getting stations from route")
            
            if let activityIndicator = strongSelf.activityIndicator {
                activityIndicator.stopAnimating()
            }
            
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                print("json station = ", json)
                
                if let jsonArrayStations = json.array {
                    
                    for jsonStation  in jsonArrayStations {
                        
                        guard let idStation = jsonStation["idParada"].int,
                            let nameStation = jsonStation["Nombre"].string,
                            let latitudStation = jsonStation["lat"].double,
                            let longitudeStation = jsonStation["long"].double,
                            let jsonRutas = jsonStation["rutas"].array
                        else {
                            print("invalid json station: ", jsonStation)
                            continue
                        }
                        
                        var rutas = [Ruta]()
                        
                        for jsonRuta in jsonRutas {
                            guard let idRuta = jsonRuta["idRuta"].int,
                                let nameRuta = jsonRuta["nombre"].string,
                                //let distance = jsonRuta["dis"].double,
                                let time = jsonRuta["tiempo"].double
                                else {
                                    print("invalid json ruta: ", jsonRuta)
                                    continue
                            }
                         
                            let ruta = Ruta(id: idRuta, nombre: nameRuta, numero: "\(idRuta)", timeLeft: time)
                            rutas.append(ruta)
                        }
                        
                        
                        let station = Station(id: idStation, nombre: nameStation, latitud: latitudStation, longitud: longitudeStation, rutas: rutas, timeToStation: 0.0)
                        
                        ruta.stations.append(station)
                    }
                    
                    if let topViewController = strongSelf.topViewController {
                        topViewController.addAnnotationsOf(stations: ruta.stations)
                    }
                    
                    strongSelf.stationStore = ruta.stations
                    
                    if let tableview = strongSelf.tableview {
                        tableview.reloadData()
                    }
                    
                }
                
            case .failure(let error):
                print("error getting stations from route: ", error)
                UIAlertController.showSimpleUnknownErrorAlertInController(controller: strongSelf)
                
            }
            
        }
                
        
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension MapPanelViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stationStore.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableview.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        
        if indexPath.row == 0 {
            cell.imageView?.image = #imageLiteral(resourceName: "firstStation")
        }
        else if indexPath.row == (stationStore.count - 1) {
            cell.imageView?.image = #imageLiteral(resourceName: "lastStation")
        }
        else {
            cell.imageView?.image = #imageLiteral(resourceName: "middleStation")
        }
        
        cell.textLabel?.text = stationStore[indexPath.row].nombre
        
        return cell        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableview.deselectRow(at: indexPath, animated: true)
        
        let selectedStation = stationStore[indexPath.row]
        
        if let stationDetailVC = storyboard?.instantiateViewController(withIdentifier: "mainVC") as? ViewController {
            stationDetailVC.station = selectedStation
            stationDetailVC.navigationItem.title = selectedStation.nombre
            navigationController?.pushViewController(stationDetailVC, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 32.0
    }
    
}
