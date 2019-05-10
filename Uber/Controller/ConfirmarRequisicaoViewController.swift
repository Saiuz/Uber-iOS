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
    case EmRequisicao, PegarPassageiro, IniciarViagem, EmViagem, ViagemFinalizada
}

class ConfirmarRequisicaoViewController: UIViewController, CLLocationManagerDelegate {
    @IBOutlet weak var mapa: MKMapView!
    @IBOutlet weak var botaAaceitarCorrida: UIButton!
    var gerenciadorLocalizacao = CLLocationManager()
    
    var nomePassageiro = ""
    var emailPassageiro = ""
    var localPassageiro = CLLocationCoordinate2D()
    var localMotorista = CLLocationCoordinate2D()
    var localDestino = CLLocationCoordinate2D()
    
    var status: StatusCorrida = .EmRequisicao // Cria uma var do tipo do enum
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configura o gerenciador de localização do Motorista
        gerenciadorLocalizacao.delegate = self // Seta que a classe vai gerenciar os recursos de localização
        gerenciadorLocalizacao.desiredAccuracy = kCLLocationAccuracyBest // Seta a precisão de localização do usuário
        gerenciadorLocalizacao.requestWhenInUseAuthorization() // Solicita autorização do usuário para usar a sua localização
        gerenciadorLocalizacao.startUpdatingLocation() // Começa a atualizar a localização do usuário
        
        // Permite a atualização de localização em background (necessário add no info.plist)
        gerenciadorLocalizacao.allowsBackgroundLocationUpdates = true
        
        // Configura área inicial do mapa
        let regiao = MKCoordinateRegion(center: self.localPassageiro, latitudinalMeters: 200, longitudinalMeters: 200)
        
        // Adiciona região no mapa
        mapa.setRegion(regiao, animated: true)
        
        // Adiciona anotação para a localização do passageiro
        let anotacaoPassageiro = MKPointAnnotation()
        anotacaoPassageiro.coordinate = self.localPassageiro
        anotacaoPassageiro.title = self.nomePassageiro
        mapa.addAnnotation(anotacaoPassageiro)
        
        // Recupera status e ajusta a interface
        let requisicoes = Database.database().reference().child("requisicoes")
        let consultaRequisicoes = requisicoes.queryOrdered(byChild: "email").queryEqual(toValue: self.emailPassageiro)
        
        // Listener que verifica se houve alteração na requisição
        consultaRequisicoes.observe(.childChanged) { (snapshot) in
            if let dados = snapshot.value as? [String: Any] {
                if let statusR = dados["status"] as? String {
                    self.recarregarTelaStatus(status: statusR, dados: dados)
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // Recupera status e ajusta a interface
        let requisicoes = Database.database().reference().child("requisicoes")
        let consultaRequisicoes = requisicoes.queryOrdered(byChild: "email").queryEqual(toValue: self.emailPassageiro)
        
        consultaRequisicoes.observeSingleEvent(of: .childAdded) { (snapshot) in
            if let dados = snapshot.value as? [String: Any] {
                if let statusR = dados["status"] as? String {
                    self.recarregarTelaStatus(status: statusR, dados: dados)
                }
            }
        }
    }
    
    func recarregarTelaStatus(status: String, dados: [String: Any]) {
        // Carrega a tela baseado nos status
        if status == StatusCorrida.PegarPassageiro.rawValue {
            print("status: PegarPassageiro")
            self.pegarPassageiro()
            
            self.exibeMotoristaPassageiro(lPartida: self.localMotorista, lDestino: self.localPassageiro, tPartida: "Meu local", tDestino: "Passageiro")
            
        } else if status == StatusCorrida.IniciarViagem.rawValue {
            print("status: IniciarViagem")
            // Modifica o status e o botão da view
            self.status = .IniciarViagem
            self.configBotaoIniciarViagem()
            
            // Recupera o local de destino
            if let latDestino = dados["destinoLatitude"] as? Double {
                if let lonDestino = dados["destinoLongitude"] as? Double {
                    // Configura o objeto de local de destino
                    self.localDestino = CLLocationCoordinate2D(latitude: latDestino, longitude: lonDestino)
                }
            }
            
            // Exibir motorista passageiro
            self.exibeMotoristaPassageiro(lPartida: self.localMotorista, lDestino: self.localPassageiro, tPartida: "Sua localização", tDestino: "Passageiro")
            
        } else if status == StatusCorrida.EmViagem.rawValue {
            // Altera o status
            self.status = .EmViagem
            
            // Altera o botão
            self.configBotaoPendenteFinalizarViagem()
            
            // Recupera o local de destino
            if let latDestino = dados["destinoLatitude"] as? Double {
                if let lonDestino = dados["destinoLongitude"] as? Double {
                    // Configura o objeto de local de destino
                    self.localDestino = CLLocationCoordinate2D(latitude: latDestino, longitude: lonDestino)
                    
                    // Exibir local do motorista e o destino
                    self.exibeMotoristaPassageiro(lPartida: self.localPassageiro, lDestino: self.localDestino, tPartida: "Sua localização", tDestino: "Destino do Passageiro")
                }
            }
        } else if status == StatusCorrida.ViagemFinalizada.rawValue {
            self.status = .ViagemFinalizada
            if let preco = dados["precoViagem"] as? Double {
                self.configBotaoViagemFinalizada(preco: preco)
            }
        }
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
                                // Atualizar status
                                self.atualizarStatusRequisicao(status: StatusCorrida.IniciarViagem.rawValue)
                            }
                            
                        } else if statusR == StatusCorrida.IniciarViagem.rawValue {
                            
                            //self.configBotaoIniciarViagem()
                            
                            // Exibir motorista passageiro
                            self.exibeMotoristaPassageiro(lPartida: self.localMotorista, lDestino: self.localPassageiro, tPartida: "Motorista", tDestino: "Passageiro")
                            
                            /*
                            if let latDestino = dados["destinoLatitude"] as? Double {
                                if let lonDestino = dados["destinoLongitude"] as? Double {
                                    // Configura o local de destino
                                    self.localDestino = CLLocationCoordinate2D(latitude: latDestino, longitude: lonDestino)
                                    
                                    
                                }
                            }
                            */
                        }
                        
                        let dadosMotorista = [
                            "motoristaLatitude" : self.localMotorista.latitude,
                            "motoristaLongitude" : self.localMotorista.longitude
                            ] as [String : Any]
                        
                        // Salvar dados no Database
                        snapshot.ref.updateChildValues(dadosMotorista)
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
        } else if self.status == StatusCorrida.IniciarViagem {
            self.iniciarViagemDestino()
        
        } else if self.status == StatusCorrida.EmViagem {
            self.finalizarViagem()
        }
    }
    
    func iniciarViagemDestino() {
        // Atualiza o status
        self.status = .EmViagem
        
        // Atualiza a requisição no database
        self.atualizarStatusRequisicao(status: self.status.rawValue) // Para o database é necessário utilizar o rawValue para salvar como string
        
        // Exibir caminho para o destino no mapa
        let destinoCLL = CLLocation(latitude: localDestino.latitude, longitude: localDestino.longitude)
        
        CLGeocoder().reverseGeocodeLocation(destinoCLL) { (local, erro) in
            if erro == nil {
                if let dadosLocal = local?.first {
                    let placeMark = MKPlacemark(placemark: dadosLocal)
                    let mapaItem = MKMapItem(placemark: placeMark)
                    mapaItem.name = "Destino do Passeiro"
                    
                    let opcoes = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
                    mapaItem.openInMaps(launchOptions: opcoes)
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
    
    func finalizarViagem() {
        // Altera o status
        self.status = .ViagemFinalizada
        
        // Calcula o preço da viagem
        let precoKM: Double = 4
        
        // Recupera dados para atualizar preco
        let requisicoes = Database.database().reference().child("requisicoes")
        let consultaRequisicoes = requisicoes.queryOrdered(byChild: "email").queryEqual(toValue: self.emailPassageiro)
        
        consultaRequisicoes.observeSingleEvent(of: .childAdded) { (snapshot) in
            if let dados = snapshot.value as? [String : Any] {
                if let latI = dados["latitude"] as? Double {
                    if let lonI = dados["longitude"] as? Double {
                        if let latD = dados["destinoLatitude"] as? Double {
                            if let lonD = dados["destinoLongitude"] as? Double {
                                // Cria locations com as latitudes para calcular a distancia
                                let inicioLocation = CLLocation(latitude: latI, longitude: lonI)
                                let destinoLocation = CLLocation(latitude: latD, longitude: lonD)
                                
                                // Calcula distancia
                                let distancia = inicioLocation.distance(from: destinoLocation)
                                let distanciaKM = distancia / 1000
                                let precoViagem = distanciaKM * precoKM
                                
                                let dadosAtualizar = [
                                    "precoViagem" : precoViagem,
                                    "distanciaPercorrida" : distanciaKM
                                ]
                                
                                // Atualiza os dados da viagem no database
                                snapshot.ref.updateChildValues(dadosAtualizar)
                                
                                // Atualiza requisicao no Database
                                self.atualizarStatusRequisicao(status: self.status.rawValue)
                                
                                // Alternar para viagem finalizada
                                self.configBotaoViagemFinalizada(preco: precoViagem)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func exibeMotoristaPassageiro(lPartida: CLLocationCoordinate2D, lDestino: CLLocationCoordinate2D, tPartida: String, tDestino: String) {
        // Exibir diretamente o passageiro e motorista no mapa
        mapa.removeAnnotations(mapa.annotations)
        
        // Calcula um raio de distancia entre usuário e motorista para configurar no mapa uma distancia que apresente as duas localizações na tela
        let latDiferenca = abs(lPartida.latitude - lDestino.latitude) * 300000 // abs = valor absoluto
        let lonDiferenca = abs(lPartida.longitude - lDestino.longitude) * 300000
        
        // Cria a região para exibir no mapa
        let regiao = MKCoordinateRegion(center: lPartida, latitudinalMeters: latDiferenca, longitudinalMeters: lonDiferenca)
        mapa.setRegion(regiao, animated: true)
        
        // Anotacao partida
        let anotacaoPartida = MKPointAnnotation()
        anotacaoPartida.coordinate = lPartida
        anotacaoPartida.title = tPartida
        mapa.addAnnotation(anotacaoPartida)
        
        // Anotacao destino
        let anotacaoDestino = MKPointAnnotation()
        anotacaoDestino.coordinate = lDestino
        anotacaoDestino.title = tDestino
        mapa.addAnnotation(anotacaoDestino)
    }
    
    func atualizarStatusRequisicao(status: String)  {
        if status != "" && self.emailPassageiro != "" {
            let requisicoes = Database.database().reference().child("requisicoes")
            let consultaRequisicao = requisicoes.queryOrdered(byChild: "email").queryEqual(toValue: self.emailPassageiro)
        
            consultaRequisicao.observeSingleEvent(of: .childAdded) { (snapshot) in
                if let dados = snapshot.value as? [String: Any] {
                    let dadosAtualizar = [
                        "status" : status
                    ]
                    
                    snapshot.ref.updateChildValues(dadosAtualizar)
                }
            }
        }
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
    
    func configBotaoPendenteFinalizarViagem() {
        self.botaAaceitarCorrida.setTitle("Finalizar Viagem", for: .normal)
        self.botaAaceitarCorrida.isEnabled = true
        self.botaAaceitarCorrida.backgroundColor = UIColor(displayP3Red: 0.899, green: 0.899, blue: 0.0, alpha: 1)
    }
    
    func configBotaoViagemFinalizada(preco: Double) {
        self.botaAaceitarCorrida.backgroundColor = UIColor(displayP3Red: 0.502, green: 0.502, blue: 0.502, alpha: 1)
        self.botaAaceitarCorrida.isEnabled = false
        
        // Formata o número
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.maximumFractionDigits = 2
        nf.locale = Locale(identifier: "pt_BR")
        
        let precoFinal = nf.string(from: NSNumber(value: preco))
        
        self.botaAaceitarCorrida.setTitle("Viagem finalizada - R$ " + precoFinal!, for: .normal)    }
}
