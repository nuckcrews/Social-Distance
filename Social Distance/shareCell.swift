//
//  shareCell.swift
//  Social Distance
//
//  Created by Nick Crews on 4/27/20.
//  Copyright © 2020 People. Love. Change. All rights reserved.
//

import UIKit

class shareCell: UICollectionViewCell {
    
    @IBOutlet weak var shareImg: UIImageView!
    @IBOutlet weak var shareTitle: UILabel!
    @IBOutlet weak var shareView: ShadowBoxWhiteScroll!
    
//    func configCell(img: String, title: String) {
//        setupLayouts()
//        if #available(iOS 13.0, *) {
//            shareImg.image = UIImage(systemName: img)
//        } else {
//            // Fallback on earlier versions
//        }
//        shareTitle.text = title
//    }
//    
    func populate(with presenter: InvitePresenter) {
      shareImg.image = presenter.icon
    
      shareTitle.text = presenter.name
    }
    
    func highlight() {
        print("high")
        shareView.fillColor = .groupTableViewBackground
        shareView.layoutSubviews()
        Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(self.unhighlight), userInfo: nil, repeats: false)
    }
    
    @objc func unhighlight() {
        print("high")
        shareView.fillColor = .white
        shareView.layoutSubviews()
    }
    
    private func setupLayouts() {
           shareView.translatesAutoresizingMaskIntoConstraints = false
           NSLayoutConstraint.activate([
           // shareView.heightAnchor.constraint(equalToConstant: 118),
               shareView.widthAnchor.constraint(equalToConstant: self.frame.width - 16)
           ])
       }
    
}
