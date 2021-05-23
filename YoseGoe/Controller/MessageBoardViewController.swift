//
//  MessageBoardViewController.swift
//  YosegakiApp
//
//  Created by 藤門莉生 on 2021/03/17.
//

import UIKit
import EMTNeumorphicView
import Firebase
import FirebaseFirestore
import SDWebImage
import AVFoundation

class MessageBoardViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate{
    
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var EMTNeumorphicView: EMTNeumorphicView!
    @IBOutlet weak var EMTNeumorphicTextView: EMTNeumorphicView!
    @IBOutlet weak var nameLabel: UILabel!
    
    var cellIndexPath: IndexPath?
    var documentID: String?
    var cellCount: Int?
    var url: NSURL?
    var name: String?
    
    
    var cellIndexPathArray: [String] = []
    var messageUrlStringArray: [String] = []
    var userProfileUrlArray: [String] = []
    let db = Firestore.firestore()
    var audioPlayer: AVAudioPlayer!
    var isPlaying = false
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.layer.cornerRadius = 20
        setUpEMTNeumorphicView(EMTNeumorphicView: EMTNeumorphicView)
        setUpEMTNeumorphicTextView(EMTNeumorphicTextView: EMTNeumorphicTextView)
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPressed(_:)))
        longPressGesture.delegate = self
        collectionView.addGestureRecognizer(longPressGesture)
        
        nameLabel.text = name!
    }
    
    override func viewWillAppear(_ animated: Bool) {
//        loadData()
    }
    
    //EMTNeumorphicViewのセットアップを行う
    func setUpEMTNeumorphicView(EMTNeumorphicView: EMTNeumorphicView) {
        EMTNeumorphicView.neumorphicLayer?.cornerType = .all
        EMTNeumorphicView.neumorphicLayer?.depthType = .convex
        EMTNeumorphicView.neumorphicLayer?.edged = false
        EMTNeumorphicView.neumorphicLayer?.cornerRadius = 20
        EMTNeumorphicView.neumorphicLayer?.elementBackgroundColor = UIColor.rgba(red: 252, green: 233, blue: 234, alpha: 1).cgColor
    }
    
    //EMTNeumorphicTextViewのセットアップを行う
    func setUpEMTNeumorphicTextView(EMTNeumorphicTextView: EMTNeumorphicView) {
        EMTNeumorphicTextView.neumorphicLayer?.cornerType = .all
        EMTNeumorphicTextView.neumorphicLayer?.depthType = .concave
        EMTNeumorphicTextView.neumorphicLayer?.edged = false
        EMTNeumorphicTextView.neumorphicLayer?.cornerRadius = 12
    }
    
    //EMTNeumorphicButtonのセットアップを行う
    func setUpButton(button: EMTNeumorphicButton, isEnabled: Bool) {
        button.layer.cornerRadius = 12
        button.isEnabled = isEnabled
    }

    //メッセージを追加ボタンのアクション
//    @IBAction func screenTransition(_ sender: Any) {
//        db.collection("MessageBoards").document(documentID!).collection("UserData").document(String(self.cellCount!)).setData(["userProfileUrl":  "", "messageUrlString": ""])
//        self.cellCount = self.cellCount! + 1
//    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 16
        //return cellCount!
    }
    
    //CollectionViewのCellの設定を行うメソッド
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        //CollectionViewのMessageCellを作成
        let messageCell = collectionView.dequeueReusableCell(withReuseIdentifier: "messageCell", for: indexPath)
        //MessageCellの背景色を設定
        messageCell.backgroundColor = UIColor.rgba(red: 252, green: 233, blue: 234, alpha: 1)
        
        let imageView = messageCell.contentView.viewWithTag(1) as! UIImageView
        
        if indexPath.row < userProfileUrlArray.count {
            imageView.sd_setImage(with: URL(string: userProfileUrlArray[indexPath.row]), completed: nil)
        }else {
            imageView.image = UIImage(named: "noprofile")
        }
        
        imageView.layer.cornerRadius = 20
        
        return messageCell
    }
    
    //CollectionViewのCellがタップされた時の処理
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        cellIndexPath = indexPath
        //RecordViewControllerに画面遷移
        performSegue(withIdentifier: "RecordVC", sender: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // segueのIDを確認して特定のsegueのときのみ動作させる
        if segue.identifier == "RecordVC" {
            // 2. 遷移先のViewControllerを取得
            let recordVC = segue.destination as? RecordViewController
            // 3. １で用意した遷移先の変数に値を渡す
            recordVC?.cellIndexPath = self.cellIndexPath

            recordVC?.documentID = self.documentID
        }
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            //横に2分割する
            let width = collectionView.bounds.width/2.0
            let height = width
            
            return CGSize(width: width, height: height)
        }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.zero
       }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
            return 0
        }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
            return 0
        }
    
    @objc func longPressed(_ sender: UILongPressGestureRecognizer) {
        let point = sender.location(in: collectionView)
        let indexPath = collectionView.indexPathForItem(at: point)
        if (indexPath == nil) {
            return
        }else if  indexPath!.row < messageUrlStringArray.count{
            self.url = NSURL(string: messageUrlStringArray[indexPath!.row])
        }else {
            return
        }
        if sender.state == .began {
            //長押し開始
            print("began press")
            //再生ボタンを押した時(再生されていないならば)
            if !isPlaying {
                //URLからファイルをダウンロードする
                downloadFileFromURL(url: self.url as! URL)
            }
        } else if sender.state == .ended {
            //長押し終了
            print("ended press")
            if audioPlayer == nil {
                return
            }
            //録音したメッセージの再生を停止する
            audioPlayer.stop()
            audioPlayer.currentTime = 0
            audioPlayer.numberOfLoops = 0
            audioPlayer.volume = 1.0
            audioPlayer.prepareToPlay()
            isPlaying = false
        }
    }
    
    func downloadFileFromURL(url:URL){
        
        var downloadTask:URLSessionDownloadTask = URLSession.shared.downloadTask(with: url as URL) { (URL, response, error) in
            
            if URL == nil {
                return
            }
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
    
    
//    func loadData() {
////        var count = 0
////        while count < cellCount! {
////            cellIndexPathArray.append(String(count))
////            count = count + 1
////        }
////
////        for indexPathCell in cellIndexPathArray{
////            db.collection("MessageBoards").document(documentID!).collection("UserData").document(indexPathCell).addSnapshotListener { (snapShot, error) in
////
////                if let error = error {
////                    print("エラーが発生しました")
////                    print("エラーの詳細：\(error.localizedDescription)")
////                    return
////                }
////
////                let data = snapShot?.data()
////                self.userProfileUrlArray.append(data!["userProfileUrl"] as! String )
////                self.messageUrlStringArray.append(data!["messageUrlString"] as! String)
////                print(self.messageUrlStringArray)
////                print(self.userProfileUrlArray)
////            }
////        }
//        db.collection("MessageBoards").document(documentID!).collection("UserData").addSnapshotListener { (snapShot, error) in
//
//            if let error = error {
//                print("エラーが発生しました")
//                print("エラーの詳細：\(error.localizedDescription)")
//                return
//            }
//
//            guard let value = snapShot else{
//                print("snapShot is nil")
//                return
//            }
//
//            value.documentChanges.forEach { (diff) in
//                if diff.type == .added {
//                    print(diff.document.data())
//                    self.collectionView.reloadData()
//                }
//            }
//        }
//    }
}

//UIColorの機能を拡大
extension UIColor {
    //RGBで色を指定できるメソッドを追加
    class func rgba(red: Int, green: Int, blue: Int, alpha: CGFloat) -> UIColor{
        return UIColor(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: alpha)
    }
}

//UIImageの機能を拡大
extension UIImage {
    // resize image
    func reSizeImage(reSize:CGSize)->UIImage {
        //UIGraphicsBeginImageContext(reSize);
        UIGraphicsBeginImageContextWithOptions(reSize,false,UIScreen.main.scale);
        self.draw(in: CGRect(x: 0, y: 0, width: reSize.width, height: reSize.height));
        let reSizeImage:UIImage! = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return reSizeImage;
    }

    // scale the image at rates
    func scaleImage(scaleSize:CGFloat)->UIImage {
        let reSize = CGSize(width: self.size.width * scaleSize, height: self.size.height * scaleSize)
        return reSizeImage(reSize: reSize)
    }
}
