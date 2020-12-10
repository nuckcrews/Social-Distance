//
//  SettingsVC.swift
//  Social Distance
//
//  Created by Nick Crews on 4/27/20.
//  Copyright © 2020 People. Love. Change. All rights reserved.
//

import UIKit
import CoreLocation
import Firebase
import FirebaseDatabase
import FirebaseAuth
import UserNotifications

class SettingsVC: UIViewController, CLLocationManagerDelegate, UNUserNotificationCenterDelegate {
    
    @IBOutlet weak var locationSegment: UISegmentedControl!
    @IBOutlet weak var notificationSegment: UISegmentedControl!
    @IBOutlet weak var notificationSegment2: UISegmentedControl!
    
    var backrgound: Bool?
    weak var delegate : SettingsVCDelegate?
    var notif: Bool?
    var orignote = 0
    var origseg = 0
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        // Do any additional setup after loading the view.
        loadsend()
        if CLLocationManager.locationServicesEnabled() {
            switch CLLocationManager.authorizationStatus() {
                case .notDetermined, .restricted, .denied, .authorizedWhenInUse:
                    self.backrgound = false
                    self.origseg = 1
                    self.locationSegment.selectedSegmentIndex = 1
                case .authorizedAlways:
                    self.backrgound = true
               self.origseg = 0
                self.locationSegment.selectedSegmentIndex = 0
                @unknown default:
                break
            }
        }
        let current = UNUserNotificationCenter.current()
        current.getNotificationSettings(completionHandler: { (settings) in
            if settings.authorizationStatus == .authorized {
                DispatchQueue.main.async {
                    self.notif = true
                    self.orignote = 0
                    self.notificationSegment.selectedSegmentIndex = 0
                }
            } else {
                DispatchQueue.main.async {
                    self.notif = false
                    self.orignote = 1
                    self.notificationSegment.selectedSegmentIndex = 1
                }
            }
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
    }

    func presentChangeNote() {
            let alert = UIAlertController(title: "Please change your notification settings to complete this update.", message: "Go to Settings", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action: UIAlertAction!) in
                self.notificationSegment.selectedSegmentIndex = self.orignote
            }))
            alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { (action: UIAlertAction!) in
              guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                  print("not opening")
                self.notificationSegment.selectedSegmentIndex = self.orignote
                  return
              }
              if UIApplication.shared.canOpenURL(settingsUrl) {
                  UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                      print("Settings opened: \(success)") // Prints true
                    self.dismiss(animated: true) {
                        print("peace")
                    }
                  })
              } else {
                   print("not opening")
              }
            }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func presentChangeLoc() {
            let alert = UIAlertController(title: "Please change your location settings to complete this update.", message: "Go to Settings", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action: UIAlertAction!) in
                self.locationSegment.selectedSegmentIndex = self.origseg
            }))
        alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { (action: UIAlertAction!) in
              guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                  print("not opening")
                self.locationSegment.selectedSegmentIndex = self.origseg
                  return
              }
              if UIApplication.shared.canOpenURL(settingsUrl) {
                  UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                      print("Settings opened: \(success)") // Prints true
                    self.dismiss(animated: true) {
                        print("peace")
                    }
                  })
              } else {
                   print("not opening")
              }
            }))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func changeLocSegment(_ sender: UISegmentedControl) {
       if sender.selectedSegmentIndex == 0 {
          print("First Segment Select")
        presentChangeLoc()
       }
       else {
          print("Second Segment Select")
        presentChangeLoc()
       }
    }
    
    @IBAction func changeNotifSegment(_ sender: UISegmentedControl) {
       if sender.selectedSegmentIndex == 0 {
          print("First Segment Select")
        self.presentChangeNote()
       }
       else {
          print("Second Segment Select")
        self.presentChangeNote()
       }
    }
    
    @IBAction func changeNotifSegment2(_ sender: UISegmentedControl) {
       if sender.selectedSegmentIndex == 0 {
          print("First Segment Select")
        self.updateSendNote(stat: "yes")
       }
       else {
          print("Second Segment Select")
            self.updateSendNote(stat: "no")
       }
    }
    
    func updateSendNote(stat: String) {
        let uid = Auth.auth().currentUser?.uid
        let ref = Database.database().reference().child("users").child(uid!)
        ref.updateChildValues(["sendNotes": stat])
        if let delegate = self.delegate {
            if stat == "yes" {
                delegate.doSomethingWith2(note: true)
            } else {
                delegate.doSomethingWith2(note: true)
            }
        }
    }
    
    func loadsend() {
        let uid = Auth.auth().currentUser?.uid
        let ref = Database.database().reference().child("users").child(uid!)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if let postDict = snapshot.value as? Dictionary<String, AnyObject> {
                let status = postDict["sendNotes"] as? String
                if status == "yes" {
                    self.notificationSegment2.selectedSegmentIndex = 0
                } else {
                    self.notificationSegment2.selectedSegmentIndex = 1
                }
            } else {
                self.notificationSegment2.selectedSegmentIndex = 0
            }
        })
    }

    @IBAction func tapBack(_ sender: UIButton) {
        self.dismiss(animated: true) {
            print("peace")
        }
    }
    
    @IBAction func linkClicked(sender: Any) {
        openUrl(urlStr: "https://distance-app.com")
    }
    
    func openUrl(urlStr: String!) {
        if let url = URL(string:urlStr), !url.absoluteString.isEmpty {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
           if let dest = segue.destination as? TutorialFullVC {
            dest.fromSet = true
        }
    }

}
protocol SettingsVCDelegate : NSObjectProtocol{
    func doSomethingWith2(note: Bool)
}
