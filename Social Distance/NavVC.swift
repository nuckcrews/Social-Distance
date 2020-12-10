//
//  NavVC.swift
//  Social Distance
//
//  Created by Nick Crews on 4/26/20.
//  Copyright © 2020 People. Love. Change. All rights reserved.
//

import UIKit

class NavVC: UINavigationController, UIGestureRecognizerDelegate {

   override func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
        self.isNavigationBarHidden = true
    
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        return viewControllers.count > 1
    }

}
