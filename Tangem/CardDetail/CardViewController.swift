//
//  CardViewController.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 dns user. All rights reserved.
//

import UIKit
import QRCode

class CardViewModel: NSObject {
    
    @IBOutlet weak var cardImageView: UIImageView!
    
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var balanceVerificationLabel: UILabel!
    @IBOutlet weak var walletBlockchainLabel: UILabel!
    
    @IBOutlet weak var networkSafetyDescriptionLabel: UILabel!
    
    @IBOutlet weak var qrCodeImageView: UIImageView!
    
    @IBOutlet weak var walletAddressLabel: UILabel!
    
    @IBOutlet weak var loadButton: UIButton! {
        didSet {
            loadButton.layer.cornerRadius = 30.0
        }
    }
    
    @IBOutlet weak var extractButton: UIButton! {
        didSet {
            extractButton.layer.cornerRadius = 30.0
        }
    }
    
    @IBOutlet weak var scanButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    
    @IBOutlet weak var exploreButton: UIButton!
    @IBOutlet weak var copyButton: UIButton!
    
}

class CardViewController: UIViewController {
    
    @IBOutlet var viewModel: CardViewModel!
    
    var cardDetails: Card?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.setupUI()
    }
    
    func setupUI() {
        guard let cardDetails = cardDetails else {
            assertionFailure()
            return
        }
        
        self.viewModel.walletBlockchainLabel.text = cardDetails.blockchain
        self.viewModel.walletAddressLabel.text = cardDetails.address
        
        var blockchainName = String()
        if cardDetails.type == .btc {
            blockchainName = "bitcoin:"
        } else {
            blockchainName = "ethereum:"
        }
        
        var qrCodeResult = QRCode(blockchainName + cardDetails.address)
        qrCodeResult?.size = self.viewModel.qrCodeImageView.frame.size
        self.viewModel.qrCodeImageView.image = qrCodeResult?.image
        
    }
    
    // MARK: Actions
    
    @IBAction func exploreButtonPressed(_ sender: Any) {
        
    }
    
    @IBAction func copyButtonPressed(_ sender: Any) {
        
    }
    
    @IBAction func loadButtonPressed(_ sender: Any) {
        
    }
    
    @IBAction func extractButtonPressed(_ sender: Any) {
        
    }
    
    @IBAction func scanButtonPressed(_ sender: Any) {
        
    }
    
    @IBAction func settingsButtonPressed(_ sender: Any) {
        
    }
    
}
