//
//  QRCodeViewController.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import Foundation
import QRCode

class QRCodeViewController: ModalActionViewController {
    
    var cardDetails: Card?
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var addressLabel: UILabel!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let cardDetails = cardDetails else {
            assertionFailure()
            return
        }
        
        var blockchainName = String()
        if cardDetails.type == .btc {
            blockchainName = "bitcoin:"
        } else {
            blockchainName = "ethereum:"
        }
        var qrCodeResult = QRCode(blockchainName + cardDetails.address)
        qrCodeResult?.size = imageView.frame.size
        imageView.image = qrCodeResult?.image
        
        addressLabel.text = cardDetails.address
    }
}
