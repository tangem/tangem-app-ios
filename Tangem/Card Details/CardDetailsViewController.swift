//
//  CardDetailsViewController.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 dns user. All rights reserved.
//

import UIKit
import QRCode

class CardDetailsViewController: UIViewController {
    
    @IBOutlet var viewModel: CardDetailsViewModel!
    
    var cardDetails: Card?
    
    var customPresentationController: CustomPresentationController?
    
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
        guard let viewController = self.storyboard?.instantiateViewController(withIdentifier: String(describing: ModalActionViewController.self)) else {
            return
        }
        
        let presentationController = CustomPresentationController(presentedViewController: viewController, presenting: self)
        self.customPresentationController = presentationController
        viewController.preferredContentSize = CGSize(width: self.view.bounds.width, height: self.view.frame.height - 200)
        //        viewController.delegate = self
        viewController.transitioningDelegate = presentationController
        self.present(viewController, animated: true, completion: nil)
        
        
    }
    
    @IBAction func scanButtonPressed(_ sender: Any) {
        
    }
    
    @IBAction func settingsButtonPressed(_ sender: Any) {
        
    }
    
}
