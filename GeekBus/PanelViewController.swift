//
//  TestViewController.swift
//  GeekBus
//
//  Created by Luis Mariano Arobes on 26/09/16.
//  Copyright © 2016 Luis Mariano Arobes. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

let API_URL =  "http://10.50.89.208:8000/api/cliente"

class PanelViewController: UIViewController {

    @IBOutlet weak var tableview: UITableView!
    @IBOutlet weak var estacionesLabel: UILabel!
    
    @IBOutlet weak var pullIndicatorView: UIView! {
        didSet {
            pullIndicatorView.roundView(radius: 4.0)
        }
    }
    
    @IBOutlet weak var stackViewRefresh: UIStackView!
    
    @IBOutlet weak var progressView: UIProgressView! {
        didSet {
            progressView.roundView()
        }
    }
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var lastRequest: Alamofire.Request?
    
    var stationStore = [Station]()
    var showingStationDetail = false
    var topViewController: ViewController?
    
    var timer = Timer()
    var countSeconds = 0;
    
    //MARK: - Override methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !showingStationDetail {
            stackViewRefresh.isHidden = false
            estacionesLabel.text = NSLocalizedString("Estaciones Cercanas", comment: "")
            getStationsNear(latitude: 19.018397, longitude: -98.241891)
        }        
        else {
            estacionesLabel.text = NSLocalizedString("Estación Seleccionada", comment: "")
            stackViewRefresh.isHidden = true
        }
        
        if traitCollection.forceTouchCapability == .available {
            print("register force touch")
            registerForPreviewing(with: self, sourceView: view)
        }
        else {
            print("no force touch")
        }
        
        setupViews()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: view)
        }
    }

    func setupViews() {
        tableview.dataSource = self
        tableview.delegate = self
        
        let cellViewNib = UINib(nibName: "StationTableViewCell", bundle: nil)
        tableview.register(cellViewNib, forCellReuseIdentifier: "StationTableViewCell")
        
        tableview.isScrollEnabled = false
        
        tableview.rowHeight = UITableViewAutomaticDimension
        tableview.estimatedRowHeight = 200
        
        tableview.separatorStyle = .none
        
        view.roundView(radius: 6.0)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        cancelTimer()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Timer methods
    func setTimer() {
        timer.invalidate()
        
        countSeconds = 0
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { (timer) in
            
            if self.countSeconds == 60 {
                self.refreshStations()
            }
            
            self.countSeconds += 1
            //print("count seconds = ", self.countSeconds)
            self.progressView.setProgress( Float(self.countSeconds) / 60.0, animated: true)
            
            
        })
    }
    
    func cancelTimer() {
        timer.invalidate()
        countSeconds = 0
    }
    
    func refreshStations() {
        guard let topViewController = topViewController else {
            return
        }
        
        getStationsNear(latitude: topViewController.mapView.centerCoordinate.latitude, longitude: topViewController.mapView.centerCoordinate.longitude)
    }
    
    func refresh() {
        stackViewRefresh.isHidden = true
        activityIndicator.startAnimating()
    }
    
    func endRefresh() {
        activityIndicator.stopAnimating()
        stackViewRefresh.isHidden = false
    }
    
    //MARK: - Store methods
    func getStationsNear( latitude: Double, longitude: Double) {
        stationStore = [Station]()
        if let topViewController = topViewController,
            let mapview = topViewController.mapView {
            mapview.removeAnnotations(mapview.annotations)
        }
        
        cancelTimer()
        refresh()
        
        print("refeshing")
        
        if let lastRequest = lastRequest {
            lastRequest.cancel()
            self.lastRequest = nil
        }
        
        lastRequest = Alamofire.request("\(API_URL)/paradas_rutas?lat=\(latitude)&long=\(longitude)&limit=50&offset=0", method: .get).responseJSON { [weak self] (response) in
            
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.endRefresh()
            strongSelf.setTimer()
            
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                print("json paradas_rutas = ", json)
                
                guard let jsonArray = json.array else {
                    print("json is not array")
                    UIAlertController.showSimpleUnknownErrorAlertInController(controller: strongSelf)
                    return
                }
                
                for stationJson in jsonArray {
                    
                    guard let nameStation = stationJson["nombre"].string,
                        let timeToStation = stationJson["tiempo"].double,
                        let idStation = stationJson["idParada"].int,
                        let latStation = stationJson["lat"].double,
                        let longStation = stationJson["long"].double,
                        let rutasJsonArray = stationJson["rutas"].array
                        else {
                            print("invalid keys in json")
                            continue
                    }
                    
                    var arrayRutas = [Ruta]()
                    
                    for rutaJson in rutasJsonArray {
                        guard let idRuta = rutaJson["idRuta"].int,
                            let nameRuta = rutaJson["nombre"].string,
                            let tiempo = rutaJson["tiempo"].double
                            else {
                                print("ruta json error = \(rutaJson)")
                                print("invalid keys in ruta Json")
                                continue
                        }
                        
                        let ruta = Ruta(id: idRuta, nombre: nameRuta, numero: "\(idRuta)", timeLeft: tiempo)
                        arrayRutas.append(ruta)
                    }
                    
                    let station = Station(id: idStation, nombre: nameStation, latitud: latStation, longitud: longStation, rutas: arrayRutas, timeToStation: timeToStation)
                    
                    strongSelf.stationStore.append(station)
                }
                
                strongSelf.tableview.reloadData()
                
                if let topViewController = strongSelf.topViewController {
                    topViewController.addAnnotationsOf(stations: strongSelf.stationStore)
                }
                
            case .failure(let error):
                print("error getting paradas_rutas: ", error)
                
                //UIAlertController.showSimpleUnknownErrorAlertInController(controller: strongSelf)
                
                /*
                var lat = latitude
                var lng = longitude
                for i in 0 ..< 6 {
                    let ruta1 = Ruta(nombre: "\(i): Mercado Zapata", numero: "45")
                    let ruta2 = Ruta(nombre: "\(i): San Alejandro", numero: "55")
                    let ruta3 = Ruta(nombre: "\(i): Loma Bella", numero: "2000")
                    
                    
                    let rutas = [ruta1, ruta2, ruta3]
                    let station = Station(nombre: "\(i): Avenida 25 Oriente, 2401", latitud: lat, longitud: lng, rutas: rutas)
                    
                    lat += 0.001
                    lng += 0.001
                    
                    strongSelf.stationStore.append(station)
                }
                
                if let topViewController = strongSelf.topViewController {
                    topViewController.addAnnotationsOf(stations: strongSelf.stationStore)
                }
                
                strongSelf.tableview.reloadData()*/
            }
        }
        
    }
    
    func addSingleStation(_ station: Station) {
        showingStationDetail = true
        stationStore = [station]
        
        if let tableview = tableview {
            tableview.reloadData()
        }
        
        if let topViewController = topViewController {
            topViewController.addAnnotationsOf(stations: stationStore)
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

//MARK: - Actions
extension PanelViewController {
    
    func tapRuta(_ ruta: Ruta) {
        print("touched ruta: ", ruta.nombre)
        
        if let rutaDetailVC = storyboard?.instantiateViewController(withIdentifier: "mapVC") as? MapViewController {
            rutaDetailVC.ruta = ruta                        
            navigationController?.pushViewController(rutaDetailVC, animated: true)
        }
    }
    
    func tapStation(recognizer: UITapGestureRecognizer) {
        if let indexPathRow = recognizer.view?.tag {
            recognizer.view?.simuateTouch()
            
            let selectedStation = stationStore[indexPathRow]
            
            if let newVC = storyboard?.instantiateViewController(withIdentifier: "mainVC") as? ViewController {
                newVC.shouldShowNavBar = true
                newVC.shouldHideNavBarWhenDisappearing = true
                newVC.station = selectedStation
                newVC.navigationItem.title = selectedStation.nombre
                navigationController?.pushViewController(newVC, animated: true)
            }
            
        }
    }
    
    @IBAction func refreshAction(_ sender: UIButton) {
        refreshStations()
    }
}

//MARK: - TableView delegate methods
extension PanelViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stationStore.count
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        /*
         if indexPath.row == 0 {
         return 0.0
         }*/
        
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        /*if let indexes = tableview.indexPathsForVisibleRows {
         for index in indexes {
         if index.row == 0 {
         tableview.isScrollEnabled = false
         }
         }
         }*/
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: "StationTableViewCell", for: indexPath) as? StationTableViewCell {
            
            if indexPath.row >= stationStore.count {
                return UITableViewCell()
            }
            
            let station = stationStore[indexPath.row]
            
            if !showingStationDetail {
                let tapStation = UITapGestureRecognizer(target: self, action: #selector(tapStation(recognizer:)))
                cell.stationView.tag = indexPath.row
                cell.stationView.addGestureRecognizer(tapStation)
            }
                        
            cell.tapRutaAction = { [weak self] (ruta) in
                print("touch ruta")
                guard let strongSelf = self else {
                    return
                }
                
                strongSelf.tapRuta(ruta)
            }
 
            
            cell.station = station
            cell.selectionStyle = .none
            return cell
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}

//MARK: - Force Touch delegate methods
extension PanelViewController: UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = tableview.indexPathForRow(at: location) else {
            return nil
        }
        
        guard let cell = tableview.cellForRow(at: indexPath) as? StationTableViewCell else {
            return nil
        }
        
        if let newVC = storyboard?.instantiateViewController(withIdentifier: "mainVC") as? ViewController {
            newVC.shouldShowNavBar = true
            newVC.shouldHideNavBarWhenDisappearing = true
            newVC.station = cell.station
            newVC.navigationItem.title = cell.station.nombre
            newVC.preferredContentSize = CGSize(width: 0.0, height: 700.0)
            
            previewingContext.sourceRect = cell.frame
            
            return newVC
        }
        
        return nil
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        showDetailViewController(viewControllerToCommit, sender: self)
    }
    
}
