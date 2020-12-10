//
//  FirstViewController.swift
//  Social Distance
//
//  Created by Nick Crews on 4/26/20.
//  Copyright © 2020 People. Love. Change. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage
import UserNotifications
import CoreLocation
import CoreBluetooth
import NVActivityIndicatorView

class FirstViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIImagePickerControllerDelegate, UNUserNotificationCenterDelegate, CBPeripheralManagerDelegate, CBCentralManagerDelegate, SettingsVCDelegate {
    
    @IBOutlet weak var userNameLbl: UITextField!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var nameBtn: UIButton!
    @IBOutlet weak var statusLbl: UILabel!
    @IBOutlet weak var comfortSlider: UISlider!
    @IBOutlet weak var comfortLabel: UILabel!
    @IBOutlet weak var defaultLabel: UILabel!
    @IBOutlet weak var closeTitleLbl: UILabel!
    @IBOutlet weak var closeCountLbl: UILabel!
    @IBOutlet weak var closeCountToday: UILabel!
    @IBOutlet weak var closeTable: UITableView!
    @IBOutlet weak var locServicesView: UIView!
    @IBOutlet weak var bubbleImg: UIImageView!
    @IBOutlet weak var playSegment: UISegmentedControl!
    @IBOutlet weak var bubbleView: UIView!
    @IBOutlet weak var logoView: UIImageView!
    @IBOutlet weak var seenTodayTitle: UILabel!
    @IBOutlet weak var liveView: NVActivityIndicatorView!
    @IBOutlet weak var tapButtonView: NVActivityIndicatorView!
    @IBOutlet weak var tapButtonView2: NVActivityIndicatorView!
    @IBOutlet weak var openingView: UIView!
    @IBOutlet weak var openingLogo: UIImageView!
    @IBOutlet weak var largeCircle: UIImageView!
    @IBOutlet weak var smallCircle: UIImageView!
    
    var localBeacon: CLBeaconRegion!
    var beaconPeripheralData: NSDictionary!
    var peripheralManager: CBPeripheralManager!

    var comfStat = "both"
    
    var tim: Timer?
    
    var humans = [human]()
    var closeHumans = [human]()
    var distances = [Double]()
    var closeToday = [String]()
    
    var userName: String?
    var userImg: String?
    var myFCM = ""
    
    var rotating = false
    var imagePicker: ImagePicker!
    
    var live = false
    var authorized = false
    let blackViewLoc = UIView()
    
    let locationManager = CLLocationManager()
    var centralManager: CBCentralManager!
    
    var beaconIDs = [String]()
    var currBeacons = [String]()
    var beaconsToRange = [CLRegion]()
    var currentClose = [human]()
    
    var notif = true
    
    var myLoc: CLLocation?
    
    var inititalAnim = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
            self.isModalInPresentation = true
        } else {
            // Fallback on earlier versions
        }
        self.openingView.translatesAutoresizingMaskIntoConstraints = false
        self.openingLogo.translatesAutoresizingMaskIntoConstraints = false
        self.openingLogo.rotate(dur: 0.6)
        self.tabBarController?.tabBar.items![1].isEnabled = false
        closeTable.delegate = self
        closeTable.dataSource = self
        userNameLbl.delegate = self
        locationManager.delegate = self

//        let firebaseAuth = Auth.auth()
//    do {
//      try firebaseAuth.signOut()
//    } catch let signOutError as NSError {
//      print ("Error signing out: %@", signOutError)
//    }
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = true
        locationManager.startUpdatingLocation()
        if Auth.auth().currentUser?.uid == nil {
            hideOpening()
            self.performSegue(withIdentifier: "toSignVC", sender: nil)
        } else {
            centralManager = CBCentralManager()
            centralManager.delegate = self
            loadActives()
            calcToday()
        }
        bubbleImg.transform = CGAffineTransform(scaleX: 1, y: -1)
        blackViewLoc.frame = self.view.frame
        blackViewLoc.alpha = 0
        blackViewLoc.backgroundColor = UIColor(white: 0, alpha: 0.5)
        self.view.addSubview(blackViewLoc)
        self.view.bringSubviewToFront(locServicesView)
        self.imagePicker = ImagePicker(presentationController: self, delegate: self)
        self.view.bringSubviewToFront(openingView)
        
        if Auth.auth().currentUser?.uid != nil {
            observer = NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: nil) { _ in
                print("willResignActive")
                if self.tim != nil {
                    self.tim?.invalidate()
                }
                self.tim = Timer.scheduledTimer(timeInterval: 900, target: self, selector: #selector(self.terminateApp), userInfo: nil, repeats: false)
            }
        }
    }
    
    var observer: NSObjectProtocol!
    deinit {
        if observer != nil {
            NotificationCenter.default.removeObserver(observer!)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        if Auth.auth().currentUser?.uid != nil {
            displayLogged()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        if Auth.auth().currentUser?.uid != nil {
            let uid = Auth.auth().currentUser?.uid
            let pushManager = PushNotificationManager(userID: uid!)
            pushManager.registerForPushNotifications()
            myFCM = AppDelegate.fcmTOKEN
        }
        if CLLocationManager.locationServicesEnabled() {
            switch CLLocationManager.authorizationStatus() {
                case .notDetermined, .restricted, .denied:
                    self.showLocServices()
                case .authorizedAlways, .authorizedWhenInUse:
                    self.authorized = true
               
                @unknown default:
                break
            }
        }
        if live {
            statusLbl.alpha = 0.0
            statusLbl.text = "You're keeping your distance!\nNice Job!"
            UIView.animate(withDuration: 0.4) {
                self.statusLbl.alpha = 1.0
            }
            if comfortLevel > 6.0 {
                self.largeCircle.rotate(dur: 3.5)
                self.smallCircle.stopRotate()
            } else if comfortLevel < 6.0 {
                self.smallCircle.rotate(dur: 3.5)
                self.largeCircle.stopRotate()
            } else {
                self.largeCircle.rotate(dur: 3.5)
                self.smallCircle.rotate(dur: 3.5)
            }
            tapButtonView.stopAnimating()
            tapButtonView2.startAnimating()
            if myFCM == "" {
                myFCM = AppDelegate.fcmTOKEN
            }
            playSegment.selectedSegmentIndex = 0
            playSegment.setSegmentStyle()
            hideBubble()
            rotating = true
            logoView.rotate(dur: 3.5)
        } else {
            self.smallCircle.stopRotate()
            self.largeCircle.stopRotate()
            statusLbl.alpha = 0.0
            statusLbl.text = "Set your comfort zone and\nstart monitoring your surroundings"
            UIView.animate(withDuration: 0.4) {
                self.statusLbl.alpha = 1.0
            }
            if !inititalAnim {
                tapButtonView2.stopAnimating()
            }
            inititalAnim = false
            stopLive()
            rotating = false
            logoView.stopRotate()
            playSegment.selectedSegmentIndex = 1
            playSegment.setSegmentStyle()
            Timer.scheduledTimer(timeInterval: 7.4, target: self, selector: #selector(self.hideBubble), userInfo: nil, repeats: false)
        }
        if tim != nil {
            tim?.invalidate()
        }
        
    }
    
    @objc func terminateApp() {
        switch UIApplication.shared.applicationState {
            case .background, .inactive:
                // background
                if live {
                    let notificationCenter = UNUserNotificationCenter.current()
                    let content = UNMutableNotificationContent()
                    content.title = "Session Expired"
                    content.body = "Your distance monitoring session has expired. Open to restart."
                    content.sound = UNNotificationSound.default
                    content.badge = 1
                    let date = Date(timeIntervalSinceNow: 2)
                    let triggerDate = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute,.second,], from: date)
                    let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
                    let req = UNNotificationRequest(identifier: "term", content: content, trigger: trigger)
                    notificationCenter.add(req) { (error) in
                        if let error = error {
                            print(error.localizedDescription)
                        }
                    }
                }
                if myUUID != nil {
                    let ref = Database.database().reference().child("actives").child(myUUID!.uuidString)
                    ref.removeValue()
                }
                exit(-1)
            case .active:
                print("in foreground")
                // foreground
            default:
                break
        }

        //UIControl().sendAction(#selector(NSXPCConnection.suspend),to: UIApplication.shared, for: nil)
    }
    
    @objc func hideBubble() {
        UIView.animate(withDuration: 0.4) {
            self.bubbleView.alpha = 0.0
        }
    }
    @objc func stopAnim() {
        inititalAnim = false
        self.tapButtonView.stopAnimating()
    }
    
    func showLocServices() {
        UIView.animate(withDuration: 0.4) {
            self.blackViewLoc.alpha = 1.0
            self.locServicesView.alpha = 1.0
        }
    }
    
    func hideLocServices() {
        UIView.animate(withDuration: 0.4) {
            self.blackViewLoc.alpha = 0.0
            self.locServicesView.alpha = 0.0
        }
    }
    
    @IBAction func tapLater(_ sender: AnyObject) {
        self.hideLocServices()
    }
    
    @IBAction func tapEnable(_ sender: AnyObject) {
        self.locationManager.requestAlwaysAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            switch CLLocationManager.authorizationStatus() {
            case .denied:
                    presentDenied()
            default:
                print("good")
            }
        }
    }
    
    func presentDenied() {
            let alert = UIAlertController(title: "Please change your location settings to use the app", message: "Go to Settings", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action: UIAlertAction!) in
                  print("Handle Ok logic here")
            }))
        alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { (action: UIAlertAction!) in
              guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                  print("not opening")
                  return
              }
              if UIApplication.shared.canOpenURL(settingsUrl) {
                  UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                      print("Settings opened: \(success)")
                  })
              } else {
                   print("not opening")
              }
            }))
        self.present(alert, animated: true, completion: nil)
    }

    func displayLogged() {
        let uid = Auth.auth().currentUser?.uid
        let ref = Database.database().reference().child("users").child(uid!)
        ref.observe(.value, with: { (snapshot) in
          let postDict = snapshot.value as? Dictionary<String, AnyObject>
            let name = postDict!["userName"]
            let url = postDict!["userImage"]
            let fcm = postDict!["fcmToken"] as? String
            let note = postDict!["sendNotes"] as? String
            if note == "yes" {
                self.notif = true
            } else {
                self.notif = true
            }
            self.myFCM = fcm!
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
            UIView.animate(withDuration: 0.4, animations: {
                self.userImageView.alpha = 1.0
                self.userNameLbl.alpha = 1.0
                self.nameBtn.alpha = 1.0
            }) { (true) in
                self.hideOpening()
            }
        } else {
            let url = URL(string: userURL)
            let task = URLSession.shared.dataTask(with: url!) { data, response, error in
                guard let data = data, error == nil else { return }
                DispatchQueue.main.async() {    // execute on main thread
                    self.userImageView.image = UIImage(data: data)
                    UIView.animate(withDuration: 0.4, animations: {
                        self.userImageView.alpha = 1.0
                        self.userNameLbl.alpha = 1.0
                        self.nameBtn.alpha = 1.0
                    }) { (true) in
                        self.hideOpening()
                    }
                }
            }
            task.resume()
        }
    }
    
    let funnyNotes = [
        "I wouldn't coome near me... I smell so bad you'll be able to taste it.",
        "I know this whole social distancing thing sticks. But hey, everyone's doing it.",
        "Come any closer and you'll be zapped by the inivisble fence!",
        "Please respect my personal space.. nothing to do with the virus, I just like to be by myself.",
        "",
        ""
    ]

    func sendNote() {
        for hum in closeHumans {
            var curr = false
            for close in currentClose {
                if hum.key == close.key {
                    curr = true
                }
            }
            if !curr {
                if notif  && hum.fcm != "" {
                    let sender = PushNotificationSender()
                    sender.sendPushNotification(to: hum.fcm, title: "You're too close!", body: "Please create more distance between yourself and others arounds you. Thank you.")
                }
                currentClose.append(hum)
            }
        }
        var count = 0
        for close2 in currentClose {
            var curr2 = false
            for hum2 in closeHumans {
                if hum2.key == close2.key {
                    curr2 = true
                }
            }
            if !curr2 {
                currentClose.remove(at: count)
            }
            count += 1
        }
    }
    
    func addToday(key: String) {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        let result = formatter.string(from: date)
        let uid = Auth.auth().currentUser?.uid
        let ref = Database.database().reference().child("users").child(uid!).child(result).child(key)
        ref.updateChildValues(["notified": "yes"])
    }
    
    func reloadTable() {
        self.closeCountLbl.text = "\(closeHumans.count)"
        if closeHumans.count == 0 {
            self.closeTable.reloadData()
            UIView.animate(withDuration: 0.4) {
                self.closeTable.alpha = 0.0
                self.closeCountLbl.alpha = 0.0
                self.closeTitleLbl.alpha = 0.0
            }
        } else {
            self.closeTable.reloadData()
            UIView.animate(withDuration: 0.4) {
                self.closeTable.alpha = 1.0
                self.closeCountLbl.alpha = 1.0
                self.closeTitleLbl.alpha = 1.0
            }
        }
        sendNote()
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
      if central.state == .poweredOn {
         print("Bluetooth is connected")
        if Auth.auth().currentUser?.uid != nil {
            initLocalBeacon()
            tapButtonView.startAnimating()
            Timer.scheduledTimer(timeInterval: 4.0, target: self, selector: #selector(self.scanAround), userInfo: nil, repeats: false)
            Timer.scheduledTimer(timeInterval: 8.0, target: self, selector: #selector(self.stopAnim), userInfo: nil, repeats: false)
        }
      } else {
        perCalled = false
        self.stopLocalBeacon()
         print("Bluetooth is not connected")
        self.canUpdate = false
        }
    }
    func hideOpening() {
        UIView.animate(withDuration: 0.4, animations: {
            self.openingView.alpha = 0.0
        }) { (true) in
            self.openingLogo.stopRotate()
            self.tabBarController?.tabBar.items![1].isEnabled = true
        }
    }
    
    func calcToday() {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        let result = formatter.string(from: date)
        let uid = Auth.auth().currentUser?.uid
        let ref = Database.database().reference().child("users").child(uid!).child(result)
        ref.observe(.value, with: {(snapshot) in
            if let snapshot = snapshot.children.allObjects as? [DataSnapshot] {
                self.closeToday.removeAll()
                for data in snapshot {
                    let key = data.key
                    self.closeToday.insert(key, at: 0)
                }
                if self.closeToday.count == 1 {
                    self.seenTodayTitle.text = "person entered your zone today"
                } else {
                    self.seenTodayTitle.text = "people entered your zone today"
                }
                self.closeCountToday.text = "\(self.closeToday.count)"
            }
        })
    }
    
    func updateLive() {
        let uid = Auth.auth().currentUser?.uid
        if myUUID != nil {
        let ref = Database.database().reference().child("actives").child(myUUID!.uuidString)
        let info: [String: AnyObject] = [
            "latitude": myLoc?.coordinate.latitude as AnyObject,
            "longitude": myLoc?.coordinate.longitude as AnyObject,
            "fcm": myFCM as AnyObject,
            "id": uid! as AnyObject
        ]
        ref.updateChildValues(info)
        }
    }
    
    func stopLive() {
        liveView.stopAnimating()
        liveView.alpha = 0
        if myUUID != nil {
            for key in currBeacons {
                stopMonitoring(key: key)
                print("stopped monitoring")
            }
            currBeacons.removeAll()
        }
    }
    
    @IBAction func indexChanged(_ sender: UISegmentedControl) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        switch playSegment.selectedSegmentIndex {
        case 0:
            statusLbl.alpha = 0.0
            statusLbl.text = "You're keeping your distance!\nNice Job!"
            UIView.animate(withDuration: 0.4) {
                self.statusLbl.alpha = 1.0
            }
            live = true
            let secondTab = tabBarController?.viewControllers![1] as! SecondViewController
            secondTab.live = true
            playSegment.setSegmentStyle()
            if !rotating {
                rotating = true
                logoView.rotate(dur: 3.5)
            }
            tapButtonView.stopAnimating()
            tapButtonView2.startAnimating()
            if comfortLevel > 6.0 {
                self.largeCircle.rotate(dur: 3.5)
                self.smallCircle.stopRotate()
            } else if comfortLevel < 6.0 {
                self.smallCircle.rotate(dur: 3.5)
                self.largeCircle.stopRotate()
            } else {
                self.largeCircle.rotate(dur: 3.5)
                self.smallCircle.rotate(dur: 3.5)
            }
        case 1:
            statusLbl.alpha = 0.0
            statusLbl.text = "Set your comfort zone and\nstart monitoring your surroundings"
            UIView.animate(withDuration: 0.4) {
                self.statusLbl.alpha = 1.0
            }
            tapButtonView2.stopAnimating()
                live = false
                if myFCM == "" {
                    myFCM = AppDelegate.fcmTOKEN
                }
                      playSegment.setSegmentStyle()
                stopLive()
                let secondTab = tabBarController?.viewControllers![1] as! SecondViewController
                secondTab.live = false
                rotating = false
                logoView.stopRotate()
            self.smallCircle.stopRotate()
            self.largeCircle.stopRotate()
        default:
            break;
        }

    }
    @IBAction func tapLogo(_ sender: Any) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        if live {
            self.statusLbl.alpha = 0.0
            statusLbl.text = "Set your comfort zone and\nstart monitoring your surroundings"
            UIView.animate(withDuration: 0.4) {
                self.statusLbl.alpha = 1.0
            }
            live = false
            if myFCM == "" {
                myFCM = AppDelegate.fcmTOKEN
            }
            playSegment.selectedSegmentIndex = 1
                  playSegment.setSegmentStyle()
            stopLive()
            let secondTab = tabBarController?.viewControllers![1] as! SecondViewController
            secondTab.live = false
            rotating = false
            logoView.stopRotate()
            tapButtonView2.stopAnimating()
            self.smallCircle.stopRotate()
            self.largeCircle.stopRotate()
        } else {
            self.statusLbl.alpha = 0.0
            statusLbl.text = "You're keeping your distance!\nNice Job!"
            UIView.animate(withDuration: 0.4) {
                self.statusLbl.alpha = 1.0
            }
            tapButtonView.stopAnimating()
            tapButtonView2.startAnimating()
            live = true
            let secondTab = tabBarController?.viewControllers![1] as! SecondViewController
            secondTab.live = true
            playSegment.selectedSegmentIndex = 0
            playSegment.setSegmentStyle()
            if !rotating {
                rotating = true
                logoView.rotate(dur: 3.5)
                if comfortLevel > 6.0 {
                    self.largeCircle.rotate(dur: 3.5)
                    self.smallCircle.stopRotate()
                } else if comfortLevel < 6.0 {
                    self.smallCircle.rotate(dur: 3.5)
                    self.largeCircle.stopRotate()
                } else {
                    self.largeCircle.rotate(dur: 3.5)
                    self.smallCircle.rotate(dur: 3.5)
                }
            }
        }
    }
    
    var comfortLevel = 6.0
    @IBAction func sliderValueChanged(_ sender: Any) {
        let val = round(comfortSlider.value)
        comfortLabel.text = "\(Int(val)) ft"
        if val == 6 {
            defaultLabel.alpha = 1
        } else {
            defaultLabel.alpha = 0
        }
        comfortSlider.value = val
        comfortLevel = Double(val)
        if comfortLevel > 6.0 {
            
            if live {
                self.largeCircle.rotate(dur: 3.5)
                self.smallCircle.stopRotate()
            }
        } else if comfortLevel < 6.0 {
            
            if live {
                self.smallCircle.rotate(dur: 3.5)
                self.largeCircle.stopRotate()
            }
        } else {
           
            if live {
                self.largeCircle.rotate(dur: 3.5)
                self.smallCircle.rotate(dur: 3.5)
            }
        }
     
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return closeHumans.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "closeCell") as? closeCell {
            cell.configCell(Human: closeHumans[indexPath.row], dist: distances[indexPath.row], notif: notif)
            return cell
        } else {
            return closeCell()
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
        print("Touched")
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? SettingsVC {
            dest.delegate = self
        }
    }
    
    public func calculateAccuracy(txPower : Double, rssi : Double) -> Double {
        if (rssi == 0) {
            return -1.0; // if we cannot determine accuracy, return -1.
        }
        let ratio :Double = rssi*1.0/txPower;
        if (ratio < 1.0) {
            return pow(ratio,10.0);
        }
        else {
            let accuracy :Double =  (0.89976)*pow(ratio,7.7095) + 0.111;
            return accuracy;
        }
    }
    
    func doSomethingWith2(note: Bool) {
        self.notif = note
    }
    
    func loadActives() {
        let uid = Auth.auth().currentUser?.uid
        let ref = Database.database().reference().child("actives")
        ref.observe(.value, with: {(snapshot) in
            if let snapshot = snapshot.children.allObjects as? [DataSnapshot] {
                self.humans.removeAll()
                self.beaconIDs.removeAll()
                if self.live {
                    for data in snapshot {
                        let key = data.key
                            if let postDict = data.value as? Dictionary<String, AnyObject> {
                                let post = human(key: key, postData: postDict)
                                self.humans.insert(post, at: 0)
                                let loc = CLLocation(latitude: post.latitude, longitude: post.longitude)
                                if self.myLoc != nil && post.id != uid {
                                    let dist = self.myLoc!.distance(from: loc)
                                  
                                    if dist < 15 {
                                        if self.beaconIDs.count < 18 {
                                            print("checking")
                                            self.beaconIDs.insert(key, at: 0)
                                            self.checkMonitor(key: key)
                                        }
                                    }
                                }
                            }
                        if self.humans.count == snapshot.count {
                            self.checkCurrent()
                        }
                    }
                }
                if snapshot.count == 0 {
                    self.checkCurrent()
                }
            } else {
                self.checkCurrent()
            }
        })
    }
    
    func loadHuman(keys: [String], dists: [Double]) {
        self.closeHumans.removeAll()
        var count = 0
        for key in keys {
        let ref = Database.database().reference().child("actives").child(key)
            ref.observeSingleEvent(of: .value) { (snapshot) in
                if let postDict = snapshot.value as? Dictionary<String, AnyObject> {
                    let post = human(key: key, postData: postDict)
                    self.closeHumans.insert(post, at: 0)
                    self.distances.insert(dists[count], at: 0)
                }
                count += 1
                if count == keys.count {
                    self.reloadTable()
                }
            }
        }
        if keys.count == 0 {
            self.reloadTable()
        }
        
    }
    
    func checkMonitor(key: String) {
        var call = true
        for curr in currBeacons {
            if key == curr {
                call = false
            }
        }
        if call {
            currBeacons.append(key)
            print("started monitoring")
            monitorBeacons(key: key)
        }
    }
    func checkCurrent() {
        var count = 0
        for curr in currBeacons {
            var rem = true
            for beac in beaconIDs {
                if curr == beac {
                    rem = false
                }
            }
            if rem {
                print("stopped monitoring")
                stopMonitoring(key: curr)
                currBeacons.remove(at: count)
            }
            count += 1
        }
    }
    
    func monitorBeacons(key: String) {
        if CLLocationManager.isMonitoringAvailable(for:
                      CLBeaconRegion.self) {
            // Match all beacons with the specified UUID
            let proximityUUID = UUID(uuidString: key)
            let beaconID = "DISTANCEBEACONS"
            let region = CLBeaconRegion(uuid: proximityUUID!, identifier: beaconID)
            self.locationManager.startMonitoring(for: region)
            
        } else {
            print("monitoring not available")
        }
    }
    
    func stopMonitoring(key: String) {
        if CLLocationManager.isMonitoringAvailable(for:
                      CLBeaconRegion.self) {
            // Match all beacons with the specified UUID
            let proximityUUID = UUID(uuidString:
                   key)
            let beaconID = "DISTANCEBEACONS"
            let region = CLBeaconRegion(uuid: proximityUUID!, identifier: beaconID)
            self.locationManager.stopMonitoring(for: region)
        
        } else {
            print("monitoring not available")
        }

    }
    
    var myUUID: UUID?
    func initLocalBeacon() {
        if localBeacon != nil {
            stopLocalBeacon()
        }
        let uuid = UUID.init()
        myUUID = uuid
        MYUUID = uuid
        localBeacon = CLBeaconRegion(uuid: uuid, identifier: "DISTANCEBEACONS")
        beaconPeripheralData = localBeacon.peripheralData(withMeasuredPower: nil)
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: nil)
        print("init local beacon")
    }
    
    func advertise() {
        print("advertising")
        peripheralManager.startAdvertising(beaconPeripheralData as? [String: Any])
    }

    func stopLocalBeacon() {
        if peripheralManager != nil {
            peripheralManager.stopAdvertising()
            peripheralManager = nil
            beaconPeripheralData = nil
            localBeacon = nil
        }
    }
    
    @objc func scanAround() {
        if self.canUpdate {
            self.advertise()
        }
    }

    var canUpdate = false
    var perCalled = false
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            print("powered on")
            canUpdate = true
        } else {
            self.canUpdate = false
             print("powered off")
        }
    }

}
extension FirstViewController: ImagePickerDelegate {

    func didSelect(image: UIImage?) {
        if image != nil {
            self.userImageView.image = image
            let uid = Auth.auth().currentUser?.uid
            self.uploadImage(image: image!, uid: uid!)
        }
    }
    
}
extension FirstViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard status == .authorized || status == .authorizedWhenInUse || status == .authorizedAlways else {
            self.authorized = false
            return
        }
        if Auth.auth().currentUser?.uid != nil {
            tapButtonView.startAnimating()
            Timer.scheduledTimer(timeInterval: 7.0, target: self, selector: #selector(self.stopAnim), userInfo: nil, repeats: false)
            self.authorized = true
            self.hideLocServices()
            loadActives()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            return
        }
        myLoc = location
        if myUUID != nil {
            self.updateLive()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region is CLBeaconRegion {
            // Start ranging only if the devices supports this service.
            if CLLocationManager.isRangingAvailable() {
                manager.startRangingBeacons(in: region as! CLBeaconRegion)
                // Store the beacon so that ranging can be stopped on demand.
                beaconsToRange.append(region as! CLBeaconRegion)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        print(region)
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        var closeBeacs = [String]()
        var closeDists = [Double]()
        for beac in beacons {
            var uuid = ""
            if #available(iOS 13.0, *) {
                uuid = beac.uuid.uuidString
            } else {
                // Fallback on earlier versions
            }
            switch beac.proximity {
                case .near, .immediate:
                    if (beac.accuracy * 3.281) <= self.comfortLevel {
                        closeBeacs.insert(uuid, at: 0)
                        closeDists.insert(beac.accuracy * 3.281, at: 0)
                        self.addToday(key: uuid)
                    }
                    break
                default:
                   // Dismiss exhibit information, if it is displayed.
                   break
            }
        }
        self.loadHuman(keys: closeBeacs, dists: closeDists)
    }
    
}
extension UIView{
    func rotate(dur: Double) {
        let rotation : CABasicAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.toValue = NSNumber(value: Double.pi * 2)
        rotation.duration = dur
        rotation.isCumulative = true
        rotation.repeatCount = .greatestFiniteMagnitude
        self.layer.add(rotation, forKey: "rotationAnimation")
    }
    func stopRotate() {
        self.layer.removeAllAnimations()
    }
}
var MYUUID: UUID?
