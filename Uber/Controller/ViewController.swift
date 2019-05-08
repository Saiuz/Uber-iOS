//
//  ViewController.swift
//  Uber
//
//  Created by Eduardo on 30/04/19.
//  Copyright © 2019 Curso IOS. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let auth = Auth.auth()
        
        // Adiciona listener (ouvinte/evento) para verificar se o usuário está logado
        auth.addStateDidChangeListener { (autenticacao, usuario) in
            // Verifica se é possível atribuir usuario á usuarioLogado, caso seja, há um usuário logado.
            if let usuarioLogado = usuario {
                let usuarios = Database.database().reference().child("usuarios").child(usuarioLogado.uid) // Nó que aponta para o usuários
                usuarios.observeSingleEvent(of: .value, with: { (snapshot) in
                    let dados = snapshot.value as? NSDictionary
                    let tipoUsuario = dados!["tipo"] as! String
                    
                    if tipoUsuario == "passageiro" {
                        // Envia o usuário para tela principal de passageiros
                        self.performSegue(withIdentifier: "seguePrincipal", sender: nil)
                    } else {
                        // Envia o usuário para tela principal de requisições para o motorista
                        self.performSegue(withIdentifier: "seguePrincipalMotorista", sender: nil)
                    }
                })
            }
        }
    }
    
    //Esconde o navigationBar
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
}
