//
//  SetYosegakiInfoViewController.swift
//  YosegakiApp
//
//  Created by 藤門莉生 on 2021/03/16.
//

import UIKit
import EMTNeumorphicView
import Firebase
import FirebaseFirestore

class SetYosegakiInfoViewController: UIViewController {
    
    var uuidString: String?
    @IBOutlet weak var saveEMTNuemorphicButton: EMTNeumorphicButton!
    @IBOutlet weak var labelEMTNeumorphicView: EMTNeumorphicView!
    @IBOutlet weak var textFieldEMTNeumorphicView: EMTNeumorphicView!
    @IBOutlet weak var nameTextFieldEMTNeumorphicView: EMTNeumorphicView!
    @IBOutlet weak var IDlLabel: UILabel!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var nameTextField: UITextField!
    let db = Firestore.firestore()
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        //ユニークなIDを生成
        self.uuidString = UUID().uuidString
        IDlLabel.text = self.uuidString
        
        //Viewのセットアップを行う
        setUpEMTNeumorphicView(emtNeumorphicView: labelEMTNeumorphicView)
        setUpEMTNeumorphicView(emtNeumorphicView: textFieldEMTNeumorphicView)
        setUpEMTNeumorphicView(emtNeumorphicView: nameTextFieldEMTNeumorphicView)
        setUpButton(button: saveEMTNuemorphicButton, isEnabled: false)
        setUpTextField(textField: passwordTextField, placeholderMessage: "設定するパスワードを入力してください")
        setUpNameTextField(textField: nameTextField, placeholderMessage: "感謝を伝える相手の名前を入力してください")
        
        //Observerを設定
        NotificationCenter.default.addObserver(self, selector: #selector(checkTextField(notification:)), name: UITextField.textDidChangeNotification, object: nil)
    }
    
    //textFieldのセットアップを行う
    func setUpTextField(textField: UITextField, placeholderMessage: String) {
        textField.borderStyle = .none
        textField.placeholder = placeholderMessage
        textField.isSecureTextEntry = true
    }
    
    //textFieldのセットアップを行う
    func setUpNameTextField(textField: UITextField, placeholderMessage: String) {
        textField.borderStyle = .none
        textField.placeholder = placeholderMessage
        textField.isSecureTextEntry = false
    }
    
    //EMTNeumorphicButtonのセットアップを行う
    func setUpButton(button: EMTNeumorphicButton, isEnabled: Bool) {
        button.layer.cornerRadius = 12
        button.isEnabled = isEnabled
    }
    
    //EMTNeumorphicViewのセットアップを行う
    func setUpEMTNeumorphicView(emtNeumorphicView: EMTNeumorphicView) {
        emtNeumorphicView.neumorphicLayer?.cornerType = .all
        emtNeumorphicView.neumorphicLayer?.depthType = .concave
        emtNeumorphicView.neumorphicLayer?.edged = false
        emtNeumorphicView.neumorphicLayer?.cornerRadius = 12
    }
    
    //「IDとパスワードを保存する」ボタンを押した時、FirebaseにIDとパスワードを保存
    @IBAction func saveIDAndPassword(_ sender: Any) {
        //collection「MessageBoards」のdocument「uuidString」に値をセット
        db.collection("MessageBoards").document(self.uuidString!).setData(["password": passwordTextField.text, "name": nameTextField.text]){ error in
            if let err = error {
                print("Error writing document: \(err)")
                return
            }else {
                print("Document successfully written!")
            }
        }
        
        //パスワードを入力するテキストフィールドを空にする
        passwordTextField.text = ""
        
        //元の画面に戻る
        self.navigationController?.popViewController(animated: true)
    }

    //テキストフィールドが入力されているかを監視する
    @objc func checkTextField(notification: Notification){
        if passwordTextField.text == "" {
            saveEMTNuemorphicButton.isEnabled = false
        }else{
            saveEMTNuemorphicButton.isEnabled = true
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
