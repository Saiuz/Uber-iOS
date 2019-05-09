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
import FirebaseAuth

// Enum = Grupo de constantes
enum StatusCorrida: String {
    case EmRequisicao, PegarPassageiro, IniciarViagem, EmViagem
}

class ConfirmarRequisicaoViewController: UIViewController {
    @IBOutlet weak var mapa: MKMapView!
    @IBOutlet weak var botaAaceitarCorrida: UIButton!
    
    var nomePassageiro = ""
    var emailPassageiro = ""
    var localPassageiro = CLLocationCoordinate2D()
    var localMotorista = CLLocationCoordinate2D()
    
    var status: StatusCorrida = .EmRequisicao // Cria uma var do tipo do enum
    
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
        if self.status == StatusCorrida.EmRequisicao {
            // Atualizar requisição no database
            let requisicoes = Database.database().reference().child("requisicoes")
            
            if let emailMotorista = Auth.auth().currentUser?.email {
                requisicoes.queryOrdered(byChild: "email").queryEqual(toValue: self.emailPassageiro).observeSingleEvent(of: .childAdded) { (snapshot) in
                    let dadosMotorista = [
                        "motoristaEmail" : emailMotorista,
                        "motoristaLatitude" : self.localMotorista.latitude,
                        "motoristaLongitude" : self.localMotorista.longitude,
                        "status" : StatusCorrida.PegarPassageiro.rawValue // rawValue converte o enum em String
                        ] as [String : Any]
                    
                    snapshot.ref.updateChildValues(dadosMotorista)
                    self.pegarPassageiro()
                }
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
        } else if true {
            
        }
    }
    
    func pegarPassageiro() {
        // Altera o status do Passageiro
        self.status = .PegarPassageiro
        
        // Alterna o botão
        self.configBotaoPegarPassageiro()
    }
    
    func configBotaoPegarPassageiro() {
        self.botaAaceitarCorrida.setTitle("A caminho do passageiro", for: .normal)
        self.botaAaceitarCorrida.isEnabled = false
        self.botaAaceitarCorrida.backgroundColor = UIColor(displayP3Red: 0.502, green: 0.502, blue: 0.502, alpha: 1)
    }
}
