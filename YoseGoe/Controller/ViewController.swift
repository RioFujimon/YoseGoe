//
//  ViewController.swift
//  YosegakiApp
//
//  Created by 藤門莉生 on 2021/03/16.
//

import UIKit
import EMTNeumorphicView
import Firebase
import FirebaseFirestore

class ViewController: UIViewController {
    
    @IBOutlet weak var IDTextFieldView: EMTNeumorphicView!
    @IBOutlet weak var IDTextField: UITextField!
    @IBOutlet weak var passwordTextFieldView: EMTNeumorphicView!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var startYosegakiButton: EMTNeumorphicButton!
    @IBOutlet weak var createIDButton: EMTNeumorphicButton!
    
    //Firestoreのインスタンスを作成
    let db = Firestore.firestore()
    
    //MessageBoardViewControllerのCollectionViewのCellの数を扱う変数
    var cellCount = 0
    //MessageBoardViewControllerのCollectionViewの
    //CellのIndexPathを格納するための配列
    var cellIndexPathArray: [String] = []
    //Firestoreから音声データが保存されているURLを取得し格納するための配列
    var messageUrlStringArray: [String] = []
    //Firestoreから画像が保存されているURLを取得し格納するための配列
    var userProfileUrlArray: [String] = []
    var name = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        //EMTNeumorphicViewのIDTextField用のViewを設定
        setUpTextFieldView(textFieldView: IDTextFieldView)
        //EMTNeumorphicViewのpasswordTextField用のViewを設定
        setUpTextFieldView(textFieldView: passwordTextFieldView)
        //IDを入力させるTextFieldの設定
        setUpTextField(textField: IDTextField, placeholderMessage: "寄せ書きのIDを入力してください", isSecureTextEntry: false)
        //パスワードを入力させるTextFieldの設定
        setUpTextField(textField: passwordTextField, placeholderMessage: "寄せ書きのパスワードを入力してください", isSecureTextEntry: true)
        //寄せ書き開始ボタンを設定
        setUpButton(button: startYosegakiButton, isEnabled: false)
        //IDとパスワードを設定させるためのViewControllerに遷移するためのボタンを設定
        setUpButton(button: createIDButton, isEnabled: true)
        
        //TextFieldが入力されているかを監視するObserverを設定
        NotificationCenter.default.addObserver(self, selector: #selector(checkTextField(notification:)), name: UITextField.textDidChangeNotification, object: nil)
    }
    
    //EMTNeumorphicViewのセットアップを行う
    func setUpTextFieldView(textFieldView: EMTNeumorphicView) {
        textFieldView.neumorphicLayer?.cornerType = .all
        textFieldView.neumorphicLayer?.depthType = .concave
        textFieldView.neumorphicLayer?.edged = false
        textFieldView.neumorphicLayer?.cornerRadius = 12
    }
    
    //textFieldのセットアップを行う
    func setUpTextField(textField: UITextField, placeholderMessage: String, isSecureTextEntry: Bool) {
        textField.borderStyle = .none
        textField.placeholder = placeholderMessage
        textField.isSecureTextEntry = isSecureTextEntry
    }
    
    //EMTNeumorphicButtonのセットアップを行う
    func setUpButton(button: EMTNeumorphicButton, isEnabled: Bool) {
        button.layer.cornerRadius = 12
        button.isEnabled = isEnabled
    }
    
    
    //寄せ書きを開始するボタンを押された時の処理
    @IBAction func startYosegaki(_ sender: Any) {
        self.userProfileUrlArray = []
        self.messageUrlStringArray = []
        //IDTextFieldまたはpasswordTextFieldに値が入力されていない時
        if IDTextField.text == "" || passwordTextField.text == "" {
            return
        }
        
        db.collection("MessageBoards").document(IDTextField.text!).collection("UserData").getDocuments { (querySnapshot, error) in
            //Collection「UserData」のdocument数を取得
            self.cellCount = querySnapshot!.count
            
            self.db.collection("MessageBoards").document(self.IDTextField.text!).collection("UserData").getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("エラーが発生しました")
                    print(error.localizedDescription)
                    return
                }
                
                for document in querySnapshot!.documents {
                    self.userProfileUrlArray.append(document.data()["userProfileUrl"] as! String)
                    self.messageUrlStringArray.append(document.data()["messageUrlString"] as! String)
                }
            }
            
            self.db.collection("MessageBoards").document(self.IDTextField.text!).getDocument { (documentSnapShot, error) in
                
                //error処理
                if let err = error {
                    print("エラーが発生しました")
                    print("エラーの詳細：\(err.localizedDescription)")
                    return
                }
                
                if let document = documentSnapShot {
                    self.name = document.data()!["name"] as! String
                    if document.data()!["password"] as! String ==  self.passwordTextField.text! {
                        //MessageBoardViewControllerに画面遷移
                        self.performSegue(withIdentifier: "MessageBoardVC", sender: nil)
                    }
                }else{
                    print("Document does not exist")
                }
                
            }
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // segueのIDを確認して特定のsegueのときのみ動作させる
        if segue.identifier == "MessageBoardVC" {
            // 2. 遷移先のViewControllerを取得
            let messageBoardVC = segue.destination as? MessageBoardViewController
            // 3. １で用意した遷移先の変数に値を渡す
            messageBoardVC?.documentID = IDTextField.text!
            messageBoardVC?.cellCount = self.cellCount
            messageBoardVC?.userProfileUrlArray = self.userProfileUrlArray
            messageBoardVC?.messageUrlStringArray = self.messageUrlStringArray
            print(self.name)
            messageBoardVC?.name = self.name+"さんへ"
        }
    }
    
    //新規作成ボタンが押された時の処理
    @IBAction func createID(_ sender: Any) {
        //寄せ書きのIDとパスワードを作成する画面に遷移
        performSegue(withIdentifier: "SetYosegakiInfoVC", sender: nil)
    }
    
    //テキストフィールドが入力されているかを監視する
    @objc func checkTextField(notification: Notification){
        if IDTextField.text == "" || passwordTextField.text == "" {
            startYosegakiButton.isEnabled = false
        }else{
            startYosegakiButton.isEnabled = true
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

