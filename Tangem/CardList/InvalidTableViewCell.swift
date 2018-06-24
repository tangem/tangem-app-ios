//
//  InvalidTableViewCell.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Yulia Moskaleva. All rights reserved.
//

import UIKit

class InvalidTableViewCell: UITableViewCell {
   
    //MARK: - UI for Ribbon Cases
    @IBOutlet weak var netImage: UIImageView!
    @IBOutlet weak var voidImage: UIImageView!    
    @IBOutlet weak var ribbonLabel: UILabel!
    
    
    @IBOutlet weak var backInvalid: UIView!
    
    @IBOutlet weak var cardIDLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        backInvalid.layer.shadowColor = UIColor.darkGray.cgColor
        backInvalid.layer.shadowOpacity = 0.5
        backInvalid.layer.shadowOffset = CGSize.zero
        backInvalid.layer.shadowRadius = 5
        //backInvalid.layer.shouldRasterize = true
        backInvalid.layer.cornerRadius = 5
        ribbonLabel.transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
