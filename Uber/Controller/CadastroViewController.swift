//
//  CadastroViewController.swift
//  Uber
//
//  Created by Eduardo on 30/04/19.
//  Copyright © 2019 Curso IOS. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class CadastroViewController: UIViewController {
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var nomeCompleto: UITextField!
    @IBOutlet weak var senha: UITextField!
    @IBOutlet weak var tipoUsuario: UISwitch!
    
    @IBOutlet weak var arredondarBotãoCadastrar: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Arredondar botão cadastrar
        arredondarBotãoCadastrar.layer.cornerRadius = 8
    }
    
    //Exibe o navigationBar
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    //Oculta o teclado ao clicar fora dos campos de textos
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    // Func do botão cadastrar
    @IBAction func cadastrar(_ sender: Any) {
        let retorno = validarCampos()
        if retorno == "" {
            // Cadastrar usuário no Firebase
            let auth = Auth.auth()
            
            if let emailR = self.email.text {
                if let nomeR = self.nomeCompleto.text {
                    if let senhaR = self.senha.text {
                        auth.createUser(withEmail: emailR, password: senhaR) { (usuario, erro) in
                            if erro == nil {
                                // Valida se usuário está logado
                                if usuario != nil {
                                    // Configuração database
                                    let usuariosDatabase = Database.database().reference().child("usuarios")
                                    
                                    // Verifica o tipo do usuário
                                    var tipo = ""
                                    if self.tipoUsuario.isOn { // Verifica a condição do switch
                                        tipo = "passageiro"
                                    } else { //Motorista
                                        tipo = "motorista"
                                    }
                                    
                                    // Salva no Database os dados do usuários
                                    let dadosUsuario = [
                                        "email" : usuario?.user.email, // método atualizado de usuario?.email
                                        "nome" : nomeR,
                                        "tipo" : tipo
                                    ]
                                    
                                    // Salva os dados
                                    usuariosDatabase.child((usuario?.user.uid)!).setValue(dadosUsuario)
                                    
                                    /* Válida se o usuário está logado, caso esteja, será redirecionado automaticamente de acordo com
                                     o tipo de usuário com o evento criado na ViewController. */
                                } else {
                                    print("Erro ao autenticar usuário.")
                                }
                            } else {
                                print("Erro ao criar conta do usuário.")
                            }
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
        } else if (self.nomeCompleto.text?.isEmpty)! {
            return "Nome completo"
        } else if (self.senha.text?.isEmpty)! {
            return "Senha"
        }
        
        return ""
    }
}
