//
//  SecondViewController.swift
//  Social Distance
//
//  Created by Nick Crews on 4/26/20.
//  Copyright © 2020 People. Love. Change. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import Firebase
import FirebaseDynamicLinks
import FirebaseStorage
import NVActivityIndicatorView

class SecondViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var userNameLbl: UITextField!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var shareCollection: UICollectionView!
    @IBOutlet weak var bubbleImg: UIImageView!
    @IBOutlet weak var logoImg: UIImageView!
    @IBOutlet weak var nameBtn: UIButton!
    @IBOutlet weak var bubbleView: UIView!
    @IBOutlet weak var liveView: NVActivityIndicatorView!
    @IBOutlet weak var playSegment: UISegmentedControl!
    @IBOutlet weak var shadView: UIView!
    
    var userName: String?
    var userImg: String?
    
    var invitePresenters: [InvitePresenter] = []
    var shareCells = [shareCell]()
    
    var imagePicker: ImagePicker!
    
    var live = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        if #available(iOS 13.0, *) {
                 overrideUserInterfaceStyle = .light
            self.isModalInPresentation = true
             } else {
                 // Fallback on earlier versions
             }
        userNameLbl.delegate = self
        invitePresenters = DefaultInvitePresenters(presentingController: self)
        shareCollection.delegate = self
        shareCollection.dataSource = self
        if Auth.auth().currentUser?.uid == nil {
            self.performSegue(withIdentifier: "toSignVCSecond", sender: nil)
        }
        self.imagePicker = ImagePicker(presentationController: self, delegate: self)
        bubbleImg.transform = CGAffineTransform(scaleX: 1, y: -1)
        self.view.sendSubviewToBack(shadView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        if Auth.auth().currentUser?.uid != nil {
            displayLogged()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        self.shareCollection.reloadData()
        if live {
            playSegment.selectedSegmentIndex = 0
            playSegment.setSegmentStyle()
//            liveView.startAnimating()
//            liveView.alpha = 1
            hideBubble()
            logoImg.rotate(dur: 3.5)
        } else {
            logoImg.stopRotate()
            playSegment.selectedSegmentIndex = 1
            playSegment.setSegmentStyle()
            stopLive()
            Timer.scheduledTimer(timeInterval: 8.0, target: self, selector: #selector(self.hideBubble), userInfo: nil, repeats: false)
        }
    }
    
    @objc func hideBubble() {
        UIView.animate(withDuration: 0.4) {
            self.bubbleView.alpha = 0.0
        }
    }
    
    @IBAction func indexChanged(_ sender: UISegmentedControl) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        switch playSegment.selectedSegmentIndex {
        case 0:
            live = true
            let firstTab = tabBarController?.viewControllers![0] as! FirstViewController
            firstTab.live = true
            switchToDataTab()
            playSegment.setSegmentStyle()
//            liveView.startAnimating()
            logoImg.rotate(dur: 3.5)
//            liveView.alpha = 1
        case 1:
            switchToDataTab()
            live = false
            logoImg.stopRotate()
            stopLive()
            let firstTab = tabBarController?.viewControllers![0] as! FirstViewController
            firstTab.live = false
            playSegment.setSegmentStyle()
        default:
            break;
        }
    }
    
    func stopLive() {
        liveView.stopAnimating()
        liveView.alpha = 0
    }
    
    func displayLogged() {
        let uid = Auth.auth().currentUser?.uid
        let ref = Database.database().reference().child("users").child(uid!)
        ref.observe(.value, with: { (snapshot) in
          let postDict = snapshot.value as? Dictionary<String, AnyObject>
            let name = postDict!["userName"]
            let url = postDict!["userImage"]
            self.userName = name as? String
            self.userImg = url as? String
           self.displayInfo(name: self.userName!, userURL: self.userImg!)
        })
    }
    func displayInfo(name: String, userURL: String) {
        self.userNameLbl.text = name
        if userURL == "" {
            if #available(iOS 13.0, *) {
                self.userImageView.image = UIImage(systemName: "camera.circle.fill")
            } else {
                // Fallback on earlier versions
            }
            UIView.animate(withDuration: 0.4) {
                self.userImageView.alpha = 1.0
                self.userNameLbl.alpha = 1.0
                self.nameBtn.alpha = 1.0
            }
        } else {
            let url = URL(string: userURL)
            let task = URLSession.shared.dataTask(with: url!) { data, response, error in
                guard let data = data, error == nil else { return }
                DispatchQueue.main.async() {    // execute on main thread
                    self.userImageView.image = UIImage(data: data)
                    UIView.animate(withDuration: 0.4) {
                        self.userImageView.alpha = 1.0
                        self.userNameLbl.alpha = 1.0
                        self.nameBtn.alpha = 1.0
                    }
                }
            }
            task.resume()
        }
    }

    func uploadImage(image: UIImage, uid: String) {
        let ref = Storage.storage().reference().child("\(uid).png")
        if  let upData = image.jpegData(compressionQuality: 0.6) {
            _ = ref.putData(upData, metadata: nil) { (metadata, error) in
                if error != nil {
                    print("error loading")
                } else {
                     ref.downloadURL { (url, error) in
                        guard url != nil else {
                        // Uh-oh, an error occurred!
                        return
                      }
                        self.registerImg(uid: uid, metadata: url!.absoluteString)
                    }
                }
            }
        }
    }
    
    func switchToDataTab() {
        Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(switchToDataTabCont), userInfo: nil, repeats: false)
    }

    @objc func switchToDataTabCont() {
        tabBarController!.selectedIndex = 0
    }
    
    private func registerImg(uid: String, metadata: String) {
        let userRef = Database.database().reference().child("users").child(uid)
        userRef.updateChildValues(["userImage": metadata])
        userImg = metadata
    }
    
    @IBAction func tapCamera(_ sender: UIButton) {
        self.imagePicker.present(from: sender)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
       
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if userNameLbl.text == "Add Name" {
            userNameLbl.text = ""
        }
    }
       
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
        if (userNameLbl.text != "" || userNameLbl.text == "Add Name") && userNameLbl.text != nil {
            self.userName = userNameLbl.text!
            self.updateName()
        } else {
            self.userName = "Add Name"
            self.userNameLbl.text = "Add Name"
        }
    }
         
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
        if (userNameLbl.text != "" || userNameLbl.text == "Add Name") && userNameLbl.text != nil {
            self.userName = userNameLbl.text!
            self.updateName()
        } else {
            self.userName = "Add Name"
            self.userNameLbl.text = "Add Name"
        }
    }
    
    func updateName() {
        let uid = Auth.auth().currentUser?.uid
        let ref = Database.database().reference().child("users").child(uid!)
        ref.updateChildValues(["userName": self.userName!])
    }
    
    @IBAction func linkClicked(sender: Any) {
        openUrl(urlStr: "https://www.macovid19relieffund.org/")
    }
    
    func openUrl(urlStr: String!) {
        if let url = URL(string:urlStr), !url.absoluteString.isEmpty {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    private enum LayoutConstant {
        static let spacing: CGFloat = 4.0
        static let itemHeight: CGFloat = 300.0
    }
    
    func generateContentLink() -> URL {
      let baseURL = URL(string: "https://distance.page.link")!
      let domain = "https://distance.page.link"
      let linkBuilder = DynamicLinkComponents(link: baseURL, domainURIPrefix: domain)
      linkBuilder?.iOSParameters = DynamicLinkIOSParameters(bundleID: "com.PLC.Social-Distance")
      linkBuilder?.androidParameters = DynamicLinkAndroidParameters(packageName: "com.PLC.Social-Distance")

      return linkBuilder?.link ?? baseURL
    }
    
}
extension SecondViewController: ImagePickerDelegate {

    func didSelect(image: UIImage?) {
        if image != nil {
            self.userImageView.image = image
            let uid = Auth.auth().currentUser?.uid
            self.uploadImage(image: image!, uid: uid!)
        }
    }
    
}


extension SecondViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("count: \(invitePresenters.filter { $0.isAvailable } .count)")
        return invitePresenters.filter { $0.isAvailable } .count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "shareCell", for: indexPath as IndexPath) as? shareCell {
            cell.populate(with: invitePresenters.filter { $0.isAvailable} [indexPath.row])
            shareCells.insert(cell, at: indexPath.row)
            return cell
        } else {
            return shareCell()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = itemWidth(for: view.frame.width, spacing: LayoutConstant.spacing)
        return CGSize(width: width, height: LayoutConstant.itemHeight)
    }

    func itemWidth(for width: CGFloat, spacing: CGFloat) -> CGFloat {
        let itemsInRow: CGFloat = 4
        let totalSpacing: CGFloat = 2 * spacing + (itemsInRow - 1) * spacing
        let finalWidth = (width - totalSpacing) / itemsInRow

        return floor(finalWidth)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: LayoutConstant.spacing, left: LayoutConstant.spacing, bottom: LayoutConstant.spacing, right: LayoutConstant.spacing)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return LayoutConstant.spacing
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return LayoutConstant.spacing
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        shareCells[indexPath.row].highlight()
        invitePresenters.filter { $0.isAvailable } [indexPath.row].sendInvite()
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
      //  shareCells[indexPath.row].highlight()
    }
//    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
//        shareCells[indexPath.row].highlight()
//        return true
//    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
      //  shareCells[indexPath.row].unhighlight()
    }
    
}
extension UISegmentedControl {
    
    func setSegmentStyle() {
        let segAttributes: NSDictionary = [
            NSAttributedString.Key.foregroundColor: UIColor.white,
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14)
        ]
        let segAttributes2: NSDictionary = [
            NSAttributedString.Key.foregroundColor: UIColor.lightGray,
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14)
        ]
        setTitleTextAttributes(segAttributes as [NSObject : AnyObject] as? [NSAttributedString.Key : Any], for: UIControl.State.selected)
        setTitleTextAttributes(segAttributes2 as [NSObject : AnyObject] as? [NSAttributedString.Key : Any], for: UIControl.State.normal)
    }

}
