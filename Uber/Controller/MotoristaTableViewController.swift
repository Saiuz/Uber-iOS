//
//  MotoristaTableViewController.swift
//  Uber
//
//  Created by Eduardo on 07/05/19.
//  Copyright © 2019 Curso IOS. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import MapKit

class MotoristaTableViewController: UITableViewController, CLLocationManagerDelegate { // Necessário extender CLLocationManagerDelegate
    var listaRequisicoes : [DataSnapshot] = []
    var gerenciadorLocalizacao = CLLocationManager()
    var localMotorista = CLLocationCoordinate2D()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Localização do Motorista
        gerenciadorLocalizacao.delegate = self // Seta que a classe vai gerenciar os recursos de localização
        gerenciadorLocalizacao.desiredAccuracy = kCLLocationAccuracyBest // Seta a precisão de localização do usuário
        gerenciadorLocalizacao.requestWhenInUseAuthorization() // Solicita autorização do usuário para usar a sua localização
        gerenciadorLocalizacao.startUpdatingLocation() // Começa a atualizar a localização do usuário
        
        // Config database
        let requisicoes = Database.database().reference().child("requisicoes")
        
        // Recupera as requisições do Database
        requisicoes.observe(.value) { (snapshot) in
            self.listaRequisicoes = []
            if snapshot.value != nil {
                for filho in snapshot.children {
                    self.listaRequisicoes.append(filho as! DataSnapshot)
                }
            }
            
            // Recarrega novamente os dados da tableView
            self.tableView.reloadData()
        }
        
        // Listener responável por verificar se uma requisição foi removida, se sim, remove a requisição da lista
        requisicoes.observe(.childRemoved) { (snapshot) in
            var indice = 0
            // Percorrea a lista de requisições comparando cada requisição com a requisição removida
            for requisicao in self.listaRequisicoes {
                if requisicao.key == snapshot.key {
                    self.listaRequisicoes.remove(at: indice) // Ao achar a requisição removida, remove-a da lista de requisições
                }
                indice = indice + 1
            }
            self.tableView.reloadData() // Recarrega os dados na lista
        }
    }
    
    // Atualiza localização do usuário
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let coordenadas = manager.location?.coordinate {
            self.localMotorista = coordenadas
        }
    }
    
    @IBAction func deslogarMotorista(_ sender: Any) {
        do {
            try Auth.auth().signOut() // Desloga usuário logado
            dismiss(animated: true, completion: nil) // Fecha a tela atual retornando o usuário para a tela inicial
        } catch  {
            print("Não foi possível deslogar usuário")
        }
    }
    
    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.listaRequisicoes.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let celula = tableView.dequeueReusableCell(withIdentifier: "celulaMotorista", for: indexPath)

        // Configure the cell...
        let snapshot = self.listaRequisicoes[indexPath.row]
        if let dados = snapshot.value as? [String: Any]{
            // Recupera a latitude e longitude do motorista e usuário para calcular a distância entre eles
            if let latPassageiro = dados["latitude"] as? Double {
                if let lonPassageiro = dados["longitude"] as? Double {
                    let motoristaLocation = CLLocation(latitude: self.localMotorista.latitude, longitude: self.localMotorista.longitude)
                    let passageiroLocation = CLLocation(latitude: latPassageiro, longitude: lonPassageiro)
                    
                    // Recupera a distância entre dois pontos (no caso, passageiro - motorista)
                    let distanciaMetros = motoristaLocation.distance(from: passageiroLocation)
                    let distanciaFinal = round((distanciaMetros / 1000)) // round - Arredonda um número decimal
                    
                    var requisicaoMotorista = ""
                    if let emailMotoristaR = dados["motoristaEmail"] as? String {
                        if let emailMotoristaLogado = Auth.auth().currentUser?.email {
                            if emailMotoristaR == emailMotoristaLogado {
                                requisicaoMotorista = "{ANDAMENTO}"
                                
                                if let status = dados["status"] as? String {
                                    if status == "ViagemFinalizada" {
                                        requisicaoMotorista = "{FINALIZADA}"
                                    }
                                }
                            }
                        }
                    }
                    
                    if let nomePassageiro = dados["nome"] as? String {
                        celula.textLabel?.text = "\(nomePassageiro) \(requisicaoMotorista)" // Seta o título da tabela
                        celula.detailTextLabel?.text = "\(distanciaFinal) KM de distância" // Seta o subtitulo da tabela
                    }
                }
            }
        }

        return celula
    }
    
    // Método responsável por administrar cliques nas celulas da tabela
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let snapshot = self.listaRequisicoes[indexPath.row]
        
        // Método que chama outra view para exibição passando um parâmetro no sender
        self.performSegue(withIdentifier: "segueAceitarCorrida", sender: snapshot)
    }
    
    // Configura o prepare(for segue) para enviar dados para a próxima view
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueAceitarCorrida" {
            if let confirmarView = segue.destination as? ConfirmarRequisicaoViewController {
                if let snapshot = sender as? DataSnapshot {
                    if let dados = snapshot.value as? [String: Any] {
                        if let latPassageiro = dados["latitude"] as? Double {
                            if let lonPassageiro = dados["longitude"] as? Double {
                                if let nomePassageiro = dados["nome"] as? String {
                                    if let emailPassageiro = dados["email"] as? String{
                                        // Recupera os dados do passageiro
                                        let localPassageiro = CLLocationCoordinate2D(latitude: latPassageiro, longitude: lonPassageiro)
                                        
                                        // Envia os dados para a próxima viewController (ConfirmarCorrida)
                                        confirmarView.nomePassageiro = nomePassageiro
                                        confirmarView.emailPassageiro = emailPassageiro
                                        confirmarView.localPassageiro = localPassageiro
                                        
                                        // Envia dados do motorista
                                        confirmarView.localMotorista = self.localMotorista
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
