//
//  TutuorialImageVC.swift
//  Social Distance
//
//  Created by Nick Crews on 4/28/20.
//  Copyright © 2020 People. Love. Change. All rights reserved.
//

import UIKit

class TutuorialImageVC: UIViewController {

    @IBOutlet weak var stepTitle: UILabel!
    @IBOutlet weak var stepImage: UIImageView!
    @IBOutlet weak var stepIcon: UIImageView!
    
    var titleText: String?
    var backImage: UIImage?
    var iconImage: UIImage?
    let blackView = UIView()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        
        blackView.frame = self.view.frame
        blackView.backgroundColor = UIColor(white: 0, alpha: 0.4)
        self.view.addSubview(blackView)
        if backImage == nil {
            print("nil for img")
        }
        stepImage.image = backImage
        stepIcon.image = iconImage
        
        if let titleText = titleText {
            stepTitle.text = titleText
        }
       // self.view.bringSubviewToFront(stepImage)
        self.view.bringSubviewToFront(stepIcon)
        self.view.bringSubviewToFront(stepTitle)
        
    }


}
