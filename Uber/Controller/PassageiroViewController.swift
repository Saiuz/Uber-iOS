//
//  PassageiroViewController.swift
//  Uber
//
//  Created by Eduardo on 01/05/19.
//  Copyright © 2019 Curso IOS. All rights reserved.
//

import UIKit
import FirebaseAuth
import MapKit
import FirebaseDatabase

class PassageiroViewController: UIViewController, CLLocationManagerDelegate {
    @IBOutlet weak var mapa: MKMapView!
    @IBOutlet weak var botaoChamarUber: UIButton!
    var gerenciadorLocalizacao = CLLocationManager()
    var localUsuario = CLLocationCoordinate2D()
    var uberChamado = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Arredonda o button chamar uber
        botaoChamarUber.layer.cornerRadius = 8
        
        // Map
        gerenciadorLocalizacao.delegate = self // Seta que a classe vai gerenciar os recursos de localização
        gerenciadorLocalizacao.desiredAccuracy = kCLLocationAccuracyBest // Seta a precisão de localização do usuário
        gerenciadorLocalizacao.requestWhenInUseAuthorization() // Solicita autorização do usuário para usar a sua localização
        gerenciadorLocalizacao.startUpdatingLocation() // Começa a atualizar a localização do usuário
    }
    
    // Método utilizado para atualizar a localização do usuário
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Recupera as coordenadas do atual local do usuário
        if let coordenadas = manager.location?.coordinate {
            // Configura local atual do usuário
            self.localUsuario = coordenadas
            
            let regiao = MKCoordinateRegion(center: coordenadas, latitudinalMeters: 200, longitudinalMeters: 200)
            mapa.setRegion(regiao, animated: true)
            
            // Remove anotações antes de criar uma nova, para evitar que apareça várias anotações a cada atualização de localização
            mapa.removeAnnotations(mapa.annotations)
            
            //Cria uma anotação (marcador) para o local do usuário
            let anotacaoUsuario = MKPointAnnotation()
            anotacaoUsuario.coordinate = coordenadas
            anotacaoUsuario.title = "Sua localização"
            mapa.addAnnotation(anotacaoUsuario) // Adiciona o marcador no mapa
        }
    }
    
    @IBAction func deslogarUsuario(_ sender: Any) {
        do {
            try Auth.auth().signOut() // Desloga usuário logado
            dismiss(animated: true, completion: nil) // Fecha a tela atual retornando o usuário para a tela inicial
        } catch  {
            print("Não foi possível deslogar usuário")
        }
    }
    
    // Método para chamar uber
    @IBAction func chamarUber(_ sender: Any) {
        let requisicao = Database.database().reference().child("requisicoes")
        
        if let emailUsuario = Auth.auth().currentUser?.email {
            if self.uberChamado { //Uber chamado
                self.configBotaoChamarUber() // Alterna a configuração do botão para cancelarUber
                
                // Utiliza uma query para obter as requisições ordenadas por e-mail
                // Após utiliza outra query para obter as requisições do e-mail especifico do usuário
                requisicao.queryOrdered(byChild: "email").queryEqual(toValue: emailUsuario).observeSingleEvent(of: .childAdded) { (snapshot) in
                    // Remove requisição do Database
                    snapshot.ref.removeValue()
                }
            } else { //Uber não foi chamado
                self.configBotaoCancelarUber() // Alterna a configuração do botão para cancelarUber
                
                if let idUsuario = Auth.auth().currentUser?.uid {
                    // Recupera nome do usuário
                    let usuarios = Database.database().reference().child("usuarios").child(idUsuario)
                    usuarios.observeSingleEvent(of: .value) { (snapshot) in
                        let dados = snapshot.value as? NSDictionary
                        let nomeUsuario = dados!["nome"] as? String
                        
                        // Salva os dados da requisição
                        let dadosUsuario = [
                            "email" : emailUsuario,
                            "nome" : nomeUsuario,
                            "latitude" : self.localUsuario.latitude,
                            "longitude" : self.localUsuario.longitude
                            ] as [String : Any]
                        
                        requisicao.childByAutoId().setValue(dadosUsuario) // childByAutoId(): Gera um identificador único no firebase
                    }
                }
            }
        } else {
            print("Erro")
        }
    }
    
    func configBotaoChamarUber() {
        self.botaoChamarUber.setTitle("Chamar Uber", for: .normal)
        self.botaoChamarUber.backgroundColor = UIColor(displayP3Red: 0.067, green: 0.576, blue: 0.604, alpha: 1)
        self.uberChamado = false
    }
    
    func configBotaoCancelarUber() {
        self.botaoChamarUber.setTitle("Cancelar Uber", for: .normal)
        self.botaoChamarUber.backgroundColor = UIColor(displayP3Red: 0.831, green: 0.237, blue: 0.146, alpha: 1)
        self.uberChamado = true
    }
}
