//
//  EntrarViewController.swift
//  Uber
//
//  Created by Eduardo on 30/04/19.
//  Copyright © 2019 Curso IOS. All rights reserved.
//

import UIKit
import FirebaseAuth

class EntrarViewController: UIViewController {
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var senha: UITextField!
    @IBOutlet weak var arredondarButtonEntrar: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Arredondar button entrar
        arredondarButtonEntrar.layer.cornerRadius = 8
    }
    
    //Exibe o navigationBar
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    //Oculta o teclado ao clicar fora dos campos de textos
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    @IBAction func entrar(_ sender: Any) {
        let retorno = validarCampos()
        let auth = Auth.auth()
        
        if retorno == "" {
            if let emailR = self.email.text {
                if let senhaR = self.senha.text {
                    auth.signIn(withEmail: emailR, password: senhaR) { (usuario, erro) in
                        if erro == nil {
                            /* Válida se o usuário está logado, caso esteja, será redirecionado automaticamente de acordo com o tipo
                               de usuário com o evento criado na ViewController. */
                            if usuario == nil {
                                print("Erro ao logar usuário")
                            }
                        } else {
                            print("Erro ao autenticar usuário.")
                        }
                    }
                }
            }
        } else {
            print("O campo \(retorno) não foi preenchido.")
        }
    }
    
    func validarCampos() -> String {
        if (self.email.text?.isEmpty)! {
            return "E-mail"
        } else if (self.senha.text?.isEmpty)! {
            return "Senha"
        }
        
        return ""
    }
}
