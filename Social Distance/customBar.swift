//
//  customBar.swift
//  Social Distance
//
//  Created by Nick Crews on 4/26/20.
//  Copyright © 2020 People. Love. Change. All rights reserved.
//

import UIKit

class customBar: UITabBar {

    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
        if #available(iOS 13.0, *) {
                 overrideUserInterfaceStyle = .light
           
             } else {
                 // Fallback on earlier versions
             }
        self.backgroundImage = UIImage.colorForNavBar(color: .white)
        self.shadowImage = UIImage.colorForNavBar(color: UIColor.init(red: 120/255.0, green: 120/255.0, blue: 120/255.0, alpha: 1.0))
    }
    

}


extension UIImage {
class func colorForNavBar(color: UIColor) -> UIImage {
    //let rect = CGRectMake(0.0, 0.0, 1.0, 1.0)

    let rect = CGRect(origin: CGPoint(x: 0,y :0), size: CGSize(width: 1.0, height: 1.0))

    UIGraphicsBeginImageContext(rect.size)
    let context = UIGraphicsGetCurrentContext()

    context!.setFillColor(color.cgColor)
    context!.fill(rect)

    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()


     return image!
    }
}
