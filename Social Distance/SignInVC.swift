//
//  SignInVC.swift
//  Social Distance
//
//  Created by Nick Crews on 4/26/20.
//  Copyright © 2020 People. Love. Change. All rights reserved.
//

import UIKit
import Foundation
import Firebase
import FirebaseUI
import Photos
import PhotosUI
import FirebaseDatabase

class SignInVC: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate {
    
    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var checkButton: UIButton!
    @IBOutlet weak var nocheckButton: UIButton!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var userNameField: UITextField!
    @IBOutlet weak var loadActive: UIActivityIndicatorView!
    
    var userID: String?
    var userName = "Add Name"
    var imagePicker: ImagePicker!
    var userImg = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 13.0, *) {
                 overrideUserInterfaceStyle = .light
            self.isModalInPresentation = true
             } else {
                 // Fallback on earlier versions
             }
        userNameField.delegate = self
        // Do any additional setup after loading the view.
        self.imagePicker = ImagePicker(presentationController: self, delegate: self)
        
    }
    
    func addUser(uid: String) {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        let result = formatter.string(from: date)
        let ref = Database.database().reference().child("users").child(uid)
        let info = [
            "userName": userName,
            "userImage": userImg,
            "sendNotes": "yes",
            "fcmToken": "",
            "signDate": result
        ]
        ref.updateChildValues(info)
        Messaging.messaging().subscribe(toTopic: "NewUser_\(result)") { error in
          print("Subscribed to weather topic")
        }
        self.performSegue(withIdentifier: "toTutorialSign", sender: nil)
        self.loadActive.alpha = 0.0
        self.loadActive.stopAnimating()
        
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
           textField.resignFirstResponder()
           return true
        
    }
       
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if userNameField.text == "Add Name & Image" {
            userNameField.text = ""
        }
    }
       
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
        if (userNameField.text != "" || userNameField.text == "Add Name & Image") && userNameField.text != nil {
            self.userName = userNameField.text!
        } else {
            self.userName = "Add Name"
            self.userNameField.text = "Add Name & Image"
        }
    }
         
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("Touched")
        self.view.endEditing(true)
        if (userNameField.text != "" || userNameField.text == "Add Name & Image") && userNameField.text != nil {
            self.userName = userNameField.text!
        } else {
            self.userName = "Add Name"
            self.userNameField.text = "Add Name & Image"
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
        addUser(uid: uid)
    }
    
    @IBAction func tapCamera(_ sender: UIButton) {
        self.userNameField.resignFirstResponder()
        self.view.endEditing(true)
        self.imagePicker.present(from: sender)
    }
    
    @IBAction func tapToCheck(_ sender: AnyObject) {
        UIView.animate(withDuration: 0.2) {
            self.checkButton.alpha = 1
            self.nocheckButton.alpha = 0
        }
    }
    @IBAction func tapNoCheck(_ sender: AnyObject) {
        UIView.animate(withDuration: 0.2) {
            self.checkButton.alpha = 0
            self.nocheckButton.alpha = 1
        }
    }
    
    var changeImg = false
    @IBAction func tapSubmit(_ sender: AnyObject) {
        if self.checkButton.alpha == 1 {
            self.loadActive.alpha = 0.4
            self.loadActive.startAnimating()
            Auth.auth().signInAnonymously() { (authResult, error) in
              // ...
                guard let user = authResult?.user else {
                    print("not logged")
                    self.loadActive.alpha = 0.0
                    self.loadActive.stopAnimating()
                    return
                }
                let uid = user.uid
                self.userID = uid
                if self.changeImg {
                    self.uploadImage(image: self.userImageView.image!, uid: uid)
                } else {
                    self.userImg = ""
                    self.addUser(uid: uid)
                }
            }
        }
    }

}

extension SignInVC: ImagePickerDelegate {

    func didSelect(image: UIImage?) {
        if image != nil {
            self.userImageView.image = image
            self.changeImg = true
        }
    }
    
}
public protocol ImagePickerDelegate: class {
    func didSelect(image: UIImage?)
}
open class ImagePicker: NSObject {

    private let pickerController: UIImagePickerController
    private weak var presentationController: UIViewController?
    private weak var delegate: ImagePickerDelegate?

    public init(presentationController: UIViewController, delegate: ImagePickerDelegate) {
        self.pickerController = UIImagePickerController()

        super.init()

        self.presentationController = presentationController
        self.delegate = delegate

        self.pickerController.delegate = self
        self.pickerController.allowsEditing = true
        self.pickerController.mediaTypes = ["public.image"]
    }

    private func action(for type: UIImagePickerController.SourceType, title: String) -> UIAlertAction? {
        guard UIImagePickerController.isSourceTypeAvailable(type) else {
            return nil
        }

        return UIAlertAction(title: title, style: .default) { [unowned self] _ in
            self.pickerController.sourceType = type
            self.presentationController?.present(self.pickerController, animated: true)
        }
    }

    public func present(from sourceView: UIView) {

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        if let action = self.action(for: .camera, title: "Take photo") {
            alertController.addAction(action)
        }
        if let action = self.action(for: .savedPhotosAlbum, title: "Camera roll") {
            alertController.addAction(action)
        }
        if let action = self.action(for: .photoLibrary, title: "Photo library") {
            alertController.addAction(action)
        }

        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        if UIDevice.current.userInterfaceIdiom == .pad {
            alertController.popoverPresentationController?.sourceView = sourceView
            alertController.popoverPresentationController?.sourceRect = sourceView.bounds
            alertController.popoverPresentationController?.permittedArrowDirections = [.down, .up]
        }

        self.presentationController?.present(alertController, animated: true)
    }

    private func pickerController(_ controller: UIImagePickerController, didSelect image: UIImage?) {
        controller.dismiss(animated: true, completion: nil)

        self.delegate?.didSelect(image: image)
    }
}

extension ImagePicker: UIImagePickerControllerDelegate {

    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.pickerController(picker, didSelect: nil)
    }

    public func imagePickerController(_ picker: UIImagePickerController,
                                      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard let image = info[.editedImage] as? UIImage else {
            return self.pickerController(picker, didSelect: nil)
        }
        self.pickerController(picker, didSelect: image)
    }
}

extension ImagePicker: UINavigationControllerDelegate {

}
