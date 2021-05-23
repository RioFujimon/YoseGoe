//
//  RecordViewController.swift
//  YosegakiApp
//
//  Created by 藤門莉生 on 2021/03/20.
//

import UIKit
import AVFoundation
import EMTNeumorphicView
import Firebase
import FirebaseStorage
import FirebaseFirestore

class RecordViewController: UIViewController, AVAudioRecorderDelegate, AVAudioPlayerDelegate, UIApplicationDelegate {
    
    //録音の開始・終了を行うボタン
    @IBOutlet weak var recordButton: EMTNeumorphicButton!
    //音声データの再生・停止を行うボタン
    @IBOutlet weak var playAndStopButton: EMTNeumorphicButton!
    //データの保存を行うボタン
    @IBOutlet weak var saveButton: EMTNeumorphicButton!
    //プロフィールイメージのためのボタン
    @IBOutlet weak var profileButton: UIButton!
    //profileButtonの下に配置することでNeumorphicDesignを表現する
    @IBOutlet weak var EMTNeumorphicView: EMTNeumorphicView!
    
    var audioRecorder: AVAudioRecorder!
    var audioPlayer: AVAudioPlayer!
    //documentDirectoryのURLを格納する変数
    var documentDirectoryURL: URL?
    //録音データのURLを格納する変数
    var recordDataURL: URL?
    //レコード中かを判定する変数
    var isRecording = false
    var isPlaying = false
    //録音データファイルの名前
    var recordDataFileName = ""
    //プロフィール画像ファイル名
    var profileImageFileName = ""
    //MessageBoardViewControllerで選択されたCollectionViewのCellのIndexPath
    var cellIndexPath: IndexPath?
    //YoseGoeのdocumentID
    var documentID: String?
    var url: NSURL?
    //FireStorageに保存した画像のURL
    var imageUrlString = ""
    //FireStorageに保存した音声データのURL
    var messageUrlString = ""
    
    
    
    //Firestorageを利用するための変数
    let storage = Storage.storage()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Observerを設定
        NotificationCenter.default.addObserver(self, selector: #selector(removeDirectory(notification:)), name: UIApplication.willResignActiveNotification, object: nil)
        
        //EMTNeumorphicViewの設定
        EMTNeumorphicView.layer.cornerRadius = 85
        EMTNeumorphicView.neumorphicLayer?.depthType = .concave
        //profileButtonの設定
        profileButton.layer.cornerRadius = 85
        profileButton.addTarget(self, action: #selector(tappedProfileImageButton), for: .touchUpInside)
        
        //recordButtonの設定
        recordButton.layer.cornerRadius = 20
        recordButton.neumorphicLayer?.cornerType = .all
        recordButton.neumorphicLayer?.depthType = .convex
        
        //playAndStopButtonの設定
        playAndStopButton.layer.cornerRadius = 20
        playAndStopButton.neumorphicLayer?.cornerType = .all
        playAndStopButton.neumorphicLayer?.depthType = .convex
        
        //saveButtonの設定
        saveButton.layer.cornerRadius = 20
        saveButton.neumorphicLayer?.cornerType = .all
        saveButton.neumorphicLayer?.depthType = .convex
    }

    
    //レコードボタンを押した時の処理
    //メッセージを録音する
    @IBAction func recordMessage(_ sender: Any) {
        //録音が始まっていない時
        if !isRecording {
            //録音状態にする
            isRecording = true
            
            let session = AVAudioSession.sharedInstance()
            try! session.setCategory(AVAudioSession.Category.playAndRecord)
            try! session.setActive(true)
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            self.recordDataURL = getURL()
            
            audioRecorder = try! AVAudioRecorder(url: self.recordDataURL!, settings: settings)
            
            //audioRecorderのデリゲートを自身に設定
            audioRecorder.delegate = self
            
            //録音する
            audioRecorder.record()
        }else {
            //録音を停止する
            stopRecord(recordDataURL: self.recordDataURL!)
            saveRecordDataOnFireStorage(recordDataURL: self.recordDataURL!)
//            removeDirectory(recordDataURL: recordDataURL!)
        }
    }
    
    //録音データのURLを取得するメソッド
    private func getURL() -> URL {
        //documentDirecotryのURLを作成
        documentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        //音声ファイル名を作成
        //（遷移前のMessageBoardViewControllerのCollectionViewCellのIndex Pathを利用）
        self.recordDataFileName = "\(String(cellIndexPath![1])).m4a"
        //録音データのURLを作成
        var recordDataURL = documentDirectoryURL!.appendingPathComponent(recordDataFileName)
        
        //録音データのURLを返す
        return recordDataURL
    }
    
    //録音を停止するメソッド
    private func stopRecord(recordDataURL: URL) -> Data? {
        //録音停止状態にする
        isRecording = false
        //録音を停止する
        audioRecorder.stop()
        //録音データを取得
        let data = try? Data(contentsOf: recordDataURL)
        //録音データを返す
        return data
    }
    
    //録音したメッセージを再生、停止するメソッド
    @IBAction func playAndStopRecord(_ sender: Any) {
        //再生ボタンを押した時(再生されていないならば)
        if !isPlaying {
            //URLからファイルをダウンロードする
            downloadFileFromURL(url: url as! URL)
        }else {
            //録音したメッセージの再生を停止する
            audioPlayer.stop()
            audioPlayer.currentTime = 0
            audioPlayer.numberOfLoops = 0
            audioPlayer.volume = 1.0
            audioPlayer.prepareToPlay()
            isPlaying = false
        }
    }
    
    //再生終了時の呼び出しメソッド
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        //録音したメッセージの再生を停止する
        audioPlayer.prepareToPlay()
        isPlaying = false
    }
    
    //DocumentDirectoryを削除するメソッド
    @objc func removeDirectory(notification: Notification) {
        print("success")
        //DocumentDirectoryを削除
        //try? FileManager.default.removeItem(at: recordDataURL!)
    }
    
    //FireStorage上に録音データを保存するメソッド
    private func saveRecordDataOnFireStorage(recordDataURL: URL){
        //音声ファイル名を作成
        self.recordDataFileName = "\(String(cellIndexPath![1])).m4a"
        //rootのrefarenceを作成
        let storageRef = storage.reference()
        //録音データを保存するrefarenceを作成
        let recordDataRef = storageRef.child("recordData/\(self.documentID!)/\(self.recordDataFileName)")
        //録音データを保存する
        let upLoadTask = recordDataRef.putFile(from: recordDataURL, metadata: nil){ (url, error) in
            if let error = error {
                print("エラーが発生しました")
                print("エラーの詳細：\(error.localizedDescription)")
                return
            }
        }
        
        //この処理はfunction()を後に必ずわけるべき
        //FireStorageから音声データのURL(HTTPS)を取得
        let storageref = Storage.storage().reference(forURL: "gs://yosegoe-96eb9.appspot.com").child("recordData").child(self.documentID!).child(recordDataFileName).downloadURL { (url, error) in
            //エラー処理
            if let error = error {
                print("エラーが発生しました")
                print("エラーの詳細：\(error.localizedDescription)")
                return
            }
            //String型の文字列を取得
            var urlString = url!.absoluteString
            self.messageUrlString = urlString
            //String型のURLをNSURL型にキャストしてメンバ変数に格納
            self.url = NSURL(string: urlString)
        }
    }
    
    //プロフィール画像を選択させるメソッド
    @objc private func tappedProfileImageButton() {
        //ImagePickerControllerのインスタンスを作成
        let imagePickerController = UIImagePickerController()
        //ImagePickerControllerのデリゲートを自身に設定
        imagePickerController.delegate = self
        //画像のピンチアウト・ピンチインを可能にする
        imagePickerController.allowsEditing = true
        //ImagePickerControllerを出現させる
        self.present(imagePickerController, animated: true, completion: nil)
    }
    
    func downloadFileFromURL(url:URL){
        
        var downloadTask:URLSessionDownloadTask = URLSession.shared.downloadTask(with: url as URL) { (URL, response, error) in
            //メッセージを再生する
            self.play(url: URL!)
        }
        downloadTask.resume()
        
    }
    
    //音声を再生するメソッド
    func play(url:URL) {
        do {
            //AVAudioPlayerのインスタンスを作成
            self.audioPlayer = try AVAudioPlayer(contentsOf: url as URL)
            //バッファをプリロードする
            // 呼び出すことでplay()メソッドを呼び出した時の遅延が少なくなる
            self.audioPlayer.prepareToPlay()
            //音量を指定する
            self.audioPlayer.volume = 1.0
            //音声データを再生する
            self.audioPlayer.play()
        } catch let error as NSError {
            //self.player = nil
            print("エラーが発生しました")
            print("エラーの詳細：\(error.localizedDescription)")
        } catch {
            print("AVAudioPlayerの初期化に失敗しました")
        }
        
    }
    
    //プロフィール画像をFirestorageに保存するメソッド
    private func uploadImageToFirestorage(image: UIImage){
        let profileImage = image ?? UIImage(named: "no_profile_image")
        guard let uploadImage = profileImage?.jpegData(compressionQuality: 0.3) else {return}
        //プロフィール画像ファイル名を作成
        self.profileImageFileName = "\(String(cellIndexPath![1])).jpeg"
        //Firestorage上にプロフィール画像を保存する先のパスを作成
        let storageRef = Storage.storage().reference().child("profileImage").child(self.documentID!).child(self.profileImageFileName)
        //プロフィール画像をFireStorageに保存
        storageRef.putData(uploadImage, metadata: nil) { (metaData, error) in
            if let error = error {
                print("FireStorageへの画像の保存に失敗しました")
                print("エラーの詳細：\(error.localizedDescription)")
                return
            }
            
            //保存した画像の保存先のURLを取得する
            storageRef.downloadURL { (url, error) in
                if let error = error {
                    print("FireStorageから画像の保存先URLを取得することに失敗しました")
                    print("エラーの詳細：\(error.localizedDescription)")
                    return
                }
                
                guard let urlString = url?.absoluteString else{return}
                self.imageUrlString = urlString
                print("URLString：\(urlString)")
            }
        }
    }
    
    //画像のURLと音声データのURLをFirestoreに保存するメソッド
    @IBAction func saveDataToFirestore(_ sender: Any) {
        let db = Firestore.firestore()
        if imageUrlString != "" && messageUrlString != ""{
            var userData = UserData(userProfileImageUrl: imageUrlString, messageUrl: messageUrlString)
            
            var dbRef = db.collection("MessageBoards").document(documentID!).collection("UserData").document(String(cellIndexPath![1]))
            
            dbRef.setData(["userProfileUrl": userData.userProfileImageUrl!, "messageUrlString": userData.messageUrl], merge: true)
        }
    }
    
    
}

extension RecordViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        var uploadImage: UIImage
        
        
        if let editImage = info[.editedImage] as? UIImage {
            profileButton.setImage(editImage.withRenderingMode(.alwaysOriginal), for: .normal)
            uploadImageToFirestorage(image: editImage)
        }else if let originalImage = info[.originalImage] as? UIImage {
            profileButton.setImage(originalImage.withRenderingMode(.alwaysOriginal), for: .normal)
            uploadImageToFirestorage(image: originalImage)
        }
        
        dismiss(animated: true, completion: nil)
        
    }
}
