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
    @IBOutlet weak var enderecoDestinoCampo: UITextField!
    
    // Outlets
    @IBOutlet weak var areaEndereco: UIView!
    @IBOutlet weak var marcadorLocalPassageiro: UIView!
    @IBOutlet weak var marcadorLocalDestino: UIView!
    
    var gerenciadorLocalizacao = CLLocationManager()
    var localUsuario = CLLocationCoordinate2D()
    var localMotorista = CLLocationCoordinate2D()
    var uberChamado = false
    var uberACaminho = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Arredonda o button chamar uber
        botaoChamarUber.layer.cornerRadius = 8
        
        // Map
        gerenciadorLocalizacao.delegate = self // Seta que a classe vai gerenciar os recursos de localização
        gerenciadorLocalizacao.desiredAccuracy = kCLLocationAccuracyBest // Seta a precisão de localização do usuário
        gerenciadorLocalizacao.requestWhenInUseAuthorization() // Solicita autorização do usuário para usar a sua localização
        gerenciadorLocalizacao.startUpdatingLocation() // Começa a atualizar a localização do usuário
        
        // Configura arredondamento dos marcadores
        self.marcadorLocalPassageiro.layer.cornerRadius = 7.5
        self.marcadorLocalPassageiro.clipsToBounds = true
        self.marcadorLocalDestino.layer.cornerRadius = 7.5
        self.marcadorLocalDestino.clipsToBounds = true
        
        self.areaEndereco.layer.cornerRadius = 10
        self.areaEndereco.clipsToBounds = true
        
        // Verifica se o usuário já tem uma requisição de Uber
        if let emailUsuario = Auth.auth().currentUser?.email {
            let requisicoes = Database.database().reference().child("requisicoes")
            // Faz uma query no database ordenando a pesquisa por e-mail e em seguida filtrando pelo e-mail do usuário logado
            let consultaRequisicoes = requisicoes.queryOrdered(byChild: "email").queryEqual(toValue: emailUsuario)
            
            // Adiciona listener para quando o usuário chamar o Uber
            consultaRequisicoes.observe(.childAdded) { (snapshot) in
                if snapshot.value != nil {
                    self.configBotaoCancelarUber()
                }
            }
            
            // Adiciona listener para quando algum motorista aceitar a corrida
            consultaRequisicoes.observe(.childChanged) { (snapshot) in
                if let dados = snapshot.value as? [String: Any] {
                    if let latMotorista = dados["motoristaLatitude"] {
                        if let lonMotorista = dados["motoristaLongitude"] {
                            // Cria a localização do motorista
                            self.localMotorista = CLLocationCoordinate2D(latitude: latMotorista as! CLLocationDegrees, longitude: lonMotorista as! CLLocationDegrees)
                            
                            self.exibirMotoristaPassageiro()
                        }
                    }
                }
            }
        }
    }
    
    func exibirMotoristaPassageiro() {
        self.uberACaminho = true
        
        // Instancia distancias para motorista e passageiros para realizar o cálculo de distancia
        let motoristaLocation = CLLocation(latitude: self.localMotorista.latitude, longitude: self.localMotorista.longitude)
        let passageiroLocation = CLLocation(latitude: self.localUsuario.latitude, longitude: self.localUsuario.longitude)
        
        // Calcular distância entre motorista e passageiro
        let distancia = motoristaLocation.distance(from: passageiroLocation)
        let distanciaFinal = round((distancia/1000)) // Distancia / 1000 = distancia em KM | round arredonda o valor
        
        // Alterações no botão de chamar Uber
        self.botaoChamarUber.backgroundColor = UIColor(displayP3Red: 0.0, green: 0.800, blue: 0.0, alpha: 1)
        self.botaoChamarUber.setTitle("Motorista \(distanciaFinal) KM distante", for: .normal)
        
        // Exibir diretamente o passageiro e motorista no mapa
        mapa.removeAnnotations(mapa.annotations)
        
        // Calcula um raio de distancia entre usuário e motorista para configurar no mapa uma distancia que apresente as duas localizações na tela
        let latDiferenca = abs(self.localUsuario.latitude - self.localMotorista.latitude) * 300000 // abs = valor absoluto
        let lonDiferenca = abs(self.localUsuario.longitude - self.localMotorista.longitude) * 300000
        
        // Cria a região para exibir no mapa
        let regiao = MKCoordinateRegion(center: self.localUsuario, latitudinalMeters: latDiferenca, longitudinalMeters: lonDiferenca)
        mapa.setRegion(regiao, animated: true)
        
        // Anotacao motorista
        let anotacaoMotorista = MKPointAnnotation()
        anotacaoMotorista.coordinate = self.localMotorista
        anotacaoMotorista.title = "Motorista"
        mapa.addAnnotation(anotacaoMotorista)
        
        // Anotacao passageiro
        let anotacaoPassageiro = MKPointAnnotation()
        anotacaoPassageiro.coordinate = self.localUsuario
        anotacaoPassageiro.title = "Sua localização"
        mapa.addAnnotation(anotacaoPassageiro)
    }
    
    // Método utilizado para atualizar a localização do usuário
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Recupera as coordenadas do atual local do usuário
        if let coordenadas = manager.location?.coordinate {
            // Configura local atual do usuário
            self.localUsuario = coordenadas
            
            if self.uberACaminho {
                self.exibirMotoristaPassageiro()
            } else {
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
                self.salvarRequisicao()
            }
        } else {
            print("Erro")
        }
    }
    
    func salvarRequisicao() {
        let requisicao = Database.database().reference().child("requisicoes")
        
        if let idUsuario = Auth.auth().currentUser?.uid {
            if let emailUsuario = Auth.auth().currentUser?.email {
                if let enderecoDestino = self.enderecoDestinoCampo.text {
                    if enderecoDestino != "" {
                        // Recupera os dados do endereço digitado (rua, cidade, cep e etx)
                        CLGeocoder().geocodeAddressString(enderecoDestino) { (local, erro) in
                            if erro == nil {
                                if let dadosLocal = local?.first {
                                    var rua = ""
                                    if dadosLocal.thoroughfare != nil {
                                        rua = dadosLocal.thoroughfare!
                                    }
                                    var numero = ""
                                    if dadosLocal.subThoroughfare != nil {
                                        numero = dadosLocal.subThoroughfare!
                                    }
                                    var bairro = ""
                                    if dadosLocal.subLocality != nil {
                                        bairro = dadosLocal.subLocality!
                                    }
                                    var cidade = ""
                                    if dadosLocal.locality != nil {
                                        cidade = dadosLocal.locality!
                                    }
                                    var cep = ""
                                    if dadosLocal.postalCode != nil {
                                        cep = dadosLocal.postalCode!
                                    }
                                    
                                    let enderecoCompleto = "\(rua), \(numero), \(bairro) - \(cidade) - \(cep)"
                                    if let latDestino = dadosLocal.location?.coordinate.latitude {
                                        if let lonDestino = dadosLocal.location?.coordinate.longitude {
                                            
                                            // Cria um alert para usuário confirmar se o local recuperado está correto
                                            let alerta = UIAlertController(title: "Confirme o seu endereço", message: enderecoCompleto, preferredStyle: .alert)
                                            let acaoCancelar = UIAlertAction(title: "Cancelar", style: .cancel, handler: nil)
                                            let acaoConfirmar = UIAlertAction(title: "Confirmar", style: .default, handler: { (alertAction) in
                                                
                                                // Recupera nome do usuário
                                                let usuarios = Database.database().reference().child("usuarios").child(idUsuario)
                                                
                                                usuarios.observeSingleEvent(of: .value) { (snapshot) in
                                                    let dados = snapshot.value as? NSDictionary
                                                    let nomeUsuario = dados!["nome"] as? String
                                                    
                                                    // Salva os dados da requisição
                                                    let dadosUsuario = [
                                                        "destinoLatitude" : latDestino,
                                                        "destinoLongitude" : lonDestino,
                                                        "email" : emailUsuario,
                                                        "nome" : nomeUsuario,
                                                        "latitude" : self.localUsuario.latitude,
                                                        "longitude" : self.localUsuario.longitude
                                                        ] as [String : Any]
                                                    
                                                    requisicao.childByAutoId().setValue(dadosUsuario) // childByAutoId(): Gera um identificador único no firebase
                                                    
                                                    // Alterna para o botão de cancelar
                                                    self.configBotaoCancelarUber() // Alterna a configuração do botão para cancelarUber
                                                }
                                            })
                                            
                                            alerta.addAction(acaoCancelar)
                                            alerta.addAction(acaoConfirmar)
                                            self.present(alerta, animated: true, completion: nil)
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        print("Endereço não digitado")
                    }
                }
            }
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
