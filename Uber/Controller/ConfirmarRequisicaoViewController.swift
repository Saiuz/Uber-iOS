//
//  ConfirmarRequisicaoViewController.swift
//  Uber
//
//  Created by Eduardo on 08/05/19.
//  Copyright © 2019 Curso IOS. All rights reserved.
//

import UIKit
import MapKit
import FirebaseDatabase

class ConfirmarRequisicaoViewController: UIViewController {
    @IBOutlet weak var mapa: MKMapView!
    
    var nomePassageiro = ""
    var emailPassageiro = ""
    var localPassageiro = CLLocationCoordinate2D()
    var localMotorista = CLLocationCoordinate2D()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configura área inicial do mapa
        let regiao = MKCoordinateRegion(center: self.localPassageiro, latitudinalMeters: 200, longitudinalMeters: 200)
        
        // Adiciona região no mapa
        mapa.setRegion(regiao, animated: true)
        
        // Adiciona anotação para a localização do passageiro
        let anotacaoPassageiro = MKPointAnnotation()
        anotacaoPassageiro.coordinate = self.localPassageiro
        anotacaoPassageiro.title = self.nomePassageiro
        mapa.addAnnotation(anotacaoPassageiro)
    }
    
    @IBAction func aceitarCorrida(_ sender: Any) {
        // Atualizar requisição no database
        let requisicoes = Database.database().reference().child("requisicoes")
        requisicoes.queryOrdered(byChild: "email").queryEqual(toValue: self.emailPassageiro).observeSingleEvent(of: .childAdded) { (snapshot) in
            let dadosMotorista = [
                "motoristaLatitude" : self.localMotorista.latitude,
                "motoristaLongitude" : self.localMotorista.longitude
            ]
            snapshot.ref.updateChildValues(dadosMotorista)
        }
        
        // Exibir o caminho até o passageiro no mapa
        let passageiroCLL = CLLocation(latitude: localPassageiro.latitude, longitude: localPassageiro.longitude)
        CLGeocoder().reverseGeocodeLocation(passageiroCLL) { (local, erro) in
            if erro == nil {
                if let dadosLocal = local?.first {
                    let placeMark = MKPlacemark(placemark: dadosLocal)
                    
                    let mapaItem = MKMapItem(placemark: placeMark)
                    mapaItem.name = self.nomePassageiro
                    
                    // Modo como a pessoa se deslocará até o local (andando, dirigindo, etc)
                    let opcoes = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                    // Abre o recurso de rotas dentro do mapa
                    mapaItem.openInMaps(launchOptions: opcoes)
                }
            }
        }
    }
}
