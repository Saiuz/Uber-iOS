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

class ConfirmarRequisicaoViewController: UIViewController, CLLocationManagerDelegate {
    @IBOutlet weak var mapa: MKMapView!
    @IBOutlet weak var botaAaceitarCorrida: UIButton!
    var gerenciadorLocalizacao = CLLocationManager()
    
    var nomePassageiro = ""
    var emailPassageiro = ""
    var localPassageiro = CLLocationCoordinate2D()
    var localMotorista = CLLocationCoordinate2D()
    
    var status: StatusCorrida = .EmRequisicao // Cria uma var do tipo do enum
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configura o gerenciador de localização do Motorista
        gerenciadorLocalizacao.delegate = self // Seta que a classe vai gerenciar os recursos de localização
        gerenciadorLocalizacao.desiredAccuracy = kCLLocationAccuracyBest // Seta a precisão de localização do usuário
        gerenciadorLocalizacao.requestWhenInUseAuthorization() // Solicita autorização do usuário para usar a sua localização
        gerenciadorLocalizacao.startUpdatingLocation() // Começa a atualizar a localização do usuário
        
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
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Recupera a coordenada do motorista
        if let coordenadas = manager.location?.coordinate {
            self.localMotorista = coordenadas
            self.atualizarLocalMotorista()
        }
    }
    
    func atualizarLocalMotorista() {
        // Atualizar a localização do motorista no firebase
        let requisicoes = Database.database().reference().child("requisicoes")
        
        if self.emailPassageiro != "" {
            // Recupera a requisição através do e-mail do usuário
            let consultaRequisicoes = requisicoes.queryOrdered(byChild: "email").queryEqual(toValue: self.emailPassageiro)
            consultaRequisicoes.observeSingleEvent(of: .childAdded) { (snapshot) in
                if let dados = snapshot.value as? [String: Any] {
                    if let statusR = dados["status"] as? String {
                        
                        // Status pegarPassageiro
                        if statusR == StatusCorrida.PegarPassageiro.rawValue { // rawValue para converter o enum em String
                            
                            /* Verifica se o Motorista está próximo, para iniciar a corrida */
                            // Calcula distância entre motorista e passageiro
                            let motoristaLocation = CLLocation(latitude: self.localMotorista.latitude, longitude: self.localMotorista.longitude)
                            let passageiroLocation = CLLocation(latitude: self.localPassageiro.latitude, longitude: self.localPassageiro.longitude)
                            
                            // Faz o calculo de distancia
                            let distancia = motoristaLocation.distance(from: passageiroLocation)
                            let distanciaKM = distancia / 1000
                            
                            var novoStatus = self.status.rawValue
                            if distanciaKM <= 0.5 {
                                novoStatus = StatusCorrida.IniciarViagem.rawValue
                            }
                            
                            let dadosMotorista = [
                                "motoristaLatitude" : self.localMotorista.latitude,
                                "motoristaLongitude" : self.localMotorista.longitude,
                                "status" : novoStatus
                                ] as [String : Any]
                            
                            // Salvar dados no Database
                            snapshot.ref.updateChildValues(dadosMotorista)
                            self.pegarPassageiro()
                            
                        } else if statusR == StatusCorrida.IniciarViagem.rawValue {
                            self.configBotaoIniciarViagem()
                        }
                    }
                }
            }
        }
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
    
    func configBotaoIniciarViagem() {
        self.botaAaceitarCorrida.setTitle("Iniciar Viagem", for: .normal)
        self.botaAaceitarCorrida.isEnabled = true
        self.botaAaceitarCorrida.backgroundColor = UIColor(displayP3Red: 0.067, green: 0.576, blue: 0.604, alpha: 1)
    }
}
