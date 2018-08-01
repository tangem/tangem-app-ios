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
        
        setupUI()
        getBalance()
        setupBalanceVerified(false)
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
    
    func verifyBalance() {
        guard let cardDetails = cardDetails else {
            assertionFailure()
            return
        }
        
        // [REDACTED_TODO_COMMENT]
        DispatchQueue.global(qos: .background).async {
            
            let result = verify(saltHex: cardDetails.salt, challengeHex: cardDetails.challenge, signatureArr: cardDetails.signArr, publicKeyArr: cardDetails.pubArr)
            
            DispatchQueue.main.async {
                self.viewModel.balanceVerificationActivityIndicator.stopAnimating()
                self.setupBalanceVerified(result)
            }
        }
    }
    
    func setupBalanceVerified(_ verified: Bool) {
        self.viewModel.balanceVerificationLabel.text = verified ? "Verified balance" : "Unverified balance"
        self.viewModel.balanceVerificationLabel.textColor = verified ? UIColor.green : UIColor.red
        let verificationIconName = verified ? "icon-verified" : "icon-unverified"
        self.viewModel.balanceVefificationIconImageView.image = UIImage(named: verificationIconName)
    }
    
    func getBalance() {

        let onResult = { (card: Card) in
            guard card.error == 0 else {
                let validationAlert = UIAlertController(title: "Error", message: "Cannot obtain full wallet data", preferredStyle: .alert)
                validationAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                    self.navigationController?.popViewController(animated: true)
                }))
                self.present(validationAlert, animated: true, completion: nil)
                self.setupBalanceVerified(false)
                
                return
            }
            
            self.cardDetails = card
            self.verifyBalance()
        }
        
        DispatchQueue.global(qos: .background).async {
            guard let card = self.cardDetails else {
                return
            }
            
            switch card.type {
            case .btc:
                BalanceService.sharedInstance.getBalanceBTC(card, onResult: onResult)
            case .eth:
                BalanceService.sharedInstance.getBalanceETH(card, onResult: onResult)
            case .seed:
                BalanceService.sharedInstance.getBalanceToken(card, onResult: onResult)
            default:
                break
            }
        }
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
