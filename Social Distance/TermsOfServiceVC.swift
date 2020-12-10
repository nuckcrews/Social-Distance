//
//  TermsOfServiceVC.swift
//  Social Distance
//
//  Created by Nick Crews on 4/27/20.
//  Copyright © 2020 People. Love. Change. All rights reserved.
//

import UIKit

class TermsOfServiceVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    @IBAction func tapBack(_ sender: UIButton) {
        self.dismiss(animated: true) {
            print("peace")
        }
    }

}
