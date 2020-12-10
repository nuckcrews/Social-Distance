//
//  closeCell.swift
//  Social Distance
//
//  Created by Nick Crews on 4/26/20.
//  Copyright © 2020 People. Love. Change. All rights reserved.
//

import UIKit

class closeCell: UITableViewCell {
    
    @IBOutlet weak var closeImg: UIImageView!
    @IBOutlet weak var distanceLbl: UILabel!
    @IBOutlet weak var notifyLbl: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configCell(Human: human, dist: Double, notif: Bool) {
        let d = String(format: "%.2f", dist)
        if notif {
            notifyLbl.text = "They were notified"
        } else {
            notifyLbl.text = "Notification not sent"
        }
        distanceLbl.text = "\(d) feet"
    }

}
