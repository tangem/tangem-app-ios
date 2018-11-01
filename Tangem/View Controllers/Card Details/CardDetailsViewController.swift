//
//  CardDetailsViewController.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import UIKit
import QRCode

class CardDetailsViewController: UIViewController, TestCardParsingCapable {
    
    @IBOutlet var viewModel: CardDetailsViewModel!
    
    var cardDetails: Card?
    var isBalanceVerified = false
    
    var customPresentationController: CustomPresentationController?
    
    let operationQueue = OperationQueue()
    
    var scanner: CardScanner?
    
    var numberOfScans = 0
    var savedChallenge: String?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupWithCardDetails()
    }
    
    func setupWithCardDetails(pending: Bool = false) {
        setupUI()
        
        guard !pending else {
            return
        }
        
        viewModel.doubleScanHintLabel.isHidden = true
        
        guard let cardDetails = cardDetails else {
            assertionFailure()
            return
        }
        
        if cardDetails.isWallet {
            verifyCard()
            getBalance()
            setupBalanceIsBeingVerified()
        } else {
            viewModel.setWalletInfoLoading(false)
            setupBalanceNoWallet()
        }
    }
    
    func setupUI() {
        guard let cardDetails = cardDetails else {
            assertionFailure()
            return
        }
        
        viewModel.updateBlockchainName(cardDetails.blockchain)
        viewModel.updateWalletAddress(cardDetails.address)
        
        var blockchainName = String()
        if cardDetails.type == .btc {
            blockchainName = "bitcoin:"
        } else {
            blockchainName = "ethereum:"
        }
        
        var qrCodeResult = QRCode(blockchainName + cardDetails.address)
        qrCodeResult?.size = viewModel.qrCodeImageView.frame.size
        viewModel.qrCodeImageView.image = qrCodeResult?.image
        
        viewModel.cardImageView.image = UIImage(named: cardDetails.imageName)
        
        viewModel.balanceVerificationActivityIndicator.stopAnimating()
    }
    
    func verifyCard() {
        guard let cardDetails = cardDetails, let salt = cardDetails.salt, let challenge = cardDetails.challenge else {
            assertionFailure()
            return
        }
        
        let operation = CardVerificationOperation(saltHex: salt, challengeHex: challenge, signatureArr: cardDetails.signArr, publicKeyArr: cardDetails.pubArr) { (isGenuineCard) in
            if !isGenuineCard {
                self.handleNonGenuineTangemCard(cardDetails)
            }
        }
        
        operationQueue.addOperation(operation)
    }
    
    func getBalance() {
        
        let onResult = { (result: Result<Card>) in
            self.viewModel.setWalletInfoLoading(false)
            
            switch result {
            case .success(let card):
                self.cardDetails = card
                self.viewModel.updateWalletBalance(card.walletValue + " " + card.walletUnits)
                
                self.verifyBalance()
            case .failure:
                self.viewModel.updateWalletBalance("--")
                
                let validationAlert = UIAlertController(title: "Error", message: "Cannot obtain full wallet data", preferredStyle: .alert)
                validationAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                    self.navigationController?.popViewController(animated: true)
                }))
                self.present(validationAlert, animated: true, completion: nil)
                self.setupBalanceVerified(false)
            }
        }
        
        guard let card = self.cardDetails else {
            return
        }
        
        var operation: Operation
        
        switch card.type {
        case .btc:
            operation = BTCCardBalanceOperation(card: card, completion: onResult)
        case .eth:
            operation = ETHCardBalanceOperation(card: card, completion: onResult)
        default:
            operation = TokenCardBalanceOperation(card: card, completion: onResult)
        }
        
        operationQueue.addOperation(operation)
    }
    
    func verifyBalance() {
        guard let cardDetails = cardDetails, let challenge = cardDetails.challenge, let salt = cardDetails.salt else {
            assertionFailure()
            return
        }
        
        viewModel.balanceVerificationActivityIndicator.startAnimating()
        
        let balanceVerificationOperation = BalanceVerificationOperation(saltHex: salt, challengeHex: challenge, signatureArr: cardDetails.signArr, publicKeyArr: cardDetails.pubArr) { (result) in
            self.viewModel.balanceVerificationActivityIndicator.stopAnimating()
            self.setupBalanceVerified(result)
        }
        
        operationQueue.addOperation(balanceVerificationOperation)
    }
    
    func setupBalanceIsBeingVerified() {
        isBalanceVerified = false
        
        viewModel.qrCodeContainerView.isHidden = false
        viewModel.walletAddressLabel.isHidden = false
        
        viewModel.updateWalletBalanceIsBeingVerified()
        viewModel.loadButton.isEnabled = false
        viewModel.extractButton.isEnabled = false
        viewModel.buttonsAvailabilityView.isHidden = false
        viewModel.balanceVefificationIconImageView.image = nil
        
        viewModel.exploreButton.isEnabled = true
        viewModel.copyButton.isEnabled = true
    }
    
    func setupBalanceVerified(_ verified: Bool) {
        isBalanceVerified = verified
        
        viewModel.qrCodeContainerView.isHidden = false
        viewModel.walletAddressLabel.isHidden = false
        
        viewModel.updateWalletBalanceVerification(verified)
        viewModel.loadButton.isEnabled = verified
        viewModel.extractButton.isEnabled = verified
        viewModel.buttonsAvailabilityView.isHidden = verified
        let verificationIconName = verified ? "icon-verified" : "icon-unverified"
        viewModel.balanceVefificationIconImageView.image = UIImage(named: verificationIconName)
        
        viewModel.exploreButton.isEnabled = true
        viewModel.copyButton.isEnabled = true
    }
    
    func setupBalanceNoWallet() {
        isBalanceVerified = false
        
        viewModel.updateWalletBalance("--")
        
        viewModel.updateWalletBalanceNoWallet()
        viewModel.loadButton.isEnabled = false
        viewModel.extractButton.isEnabled = false
        viewModel.buttonsAvailabilityView.isHidden = false
        
        viewModel.balanceVefificationIconImageView.image = nil
        
        viewModel.qrCodeContainerView.isHidden = true
        viewModel.walletAddressLabel.isHidden = true
    }
    
    // MARK: Simulator parsing Operation
    
    func launchSimulationParsingOperationWith(payload: Data) {
        operationQueue.cancelAllOperations()
        viewModel.setWalletInfoLoading(true)
        
        let operation = CardParsingOperation(payload: payload) { (result) in
            DispatchQueue.main.async {
                self.handleOperationFinishedSimulatorWith(result: result)
            }
        }
        operationQueue.addOperation(operation)
    }
    
    func handleOperationFinishedSimulatorWith(result: CardParsingOperation.CardParsingResult) {
        switch result {
        case .success(let card):
            cardDetails = card
            setupWithCardDetails()
        case .locked:
            handleCardParserLockedCard()
        case .tlvError:
            handleCardParserWrongTLV()
        }
    }
    
    // MARK: Actions
    
    @IBAction func exploreButtonPressed(_ sender: Any) {
        if let link = cardDetails?.link, let url = URL(string: link) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    var dispatchWorkItem: DispatchWorkItem?
    
    @IBAction func copyButtonPressed(_ sender: Any) {
        UIPasteboard.general.string = cardDetails?.address
        
        dispatchWorkItem?.cancel()
        
        updateCopyButtonTitleForState(copied: true)
        dispatchWorkItem = DispatchWorkItem(block: {
            self.updateCopyButtonTitleForState(copied: false)
        })
        
        guard let dispatchWorkItem = dispatchWorkItem else {
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1, execute: dispatchWorkItem)
    }
    
    func updateCopyButtonTitleForState(copied: Bool) {
        let title = copied ? "Copied!" : "Copy"
        let color = copied ? UIColor.tgm_green() : UIColor.black
        
        UIView.transition(with: viewModel.copyButton, duration: 0.1, options: .transitionCrossDissolve, animations: {
            self.viewModel.copyButton.setTitle(title.uppercased(), for: .normal)
            self.viewModel.copyButton.setTitleColor(color, for: .normal)
        }, completion: nil)
    }
    
    @IBAction func loadButtonPressed(_ sender: Any) {
        guard let viewController = self.storyboard?.instantiateViewController(withIdentifier: "LoadViewController") as? LoadViewController else {
            return
        }
        
        viewController.cardDetails = cardDetails
        viewController.delegate = self
        
        let presentationController = CustomPresentationController(presentedViewController: viewController, presenting: self)
        self.customPresentationController = presentationController
        viewController.preferredContentSize = CGSize(width: self.view.bounds.width, height: 247)
        viewController.transitioningDelegate = presentationController
        self.present(viewController, animated: true, completion: nil)
    }
    
    @IBAction func extractButtonPressed(_ sender: Any) {

        guard let viewController = self.storyboard?.instantiateViewController(withIdentifier: "ExtractViewController") else {
            return
        }
        
        let presentationController = CustomPresentationController(presentedViewController: viewController, presenting: self)
        self.customPresentationController = presentationController
        viewController.preferredContentSize = CGSize(width: self.view.bounds.width, height: 247)
        viewController.transitioningDelegate = presentationController
        self.present(viewController, animated: true, completion: nil)

    }
    
    @IBAction func scanButtonPressed(_ sender: Any) {
        #if targetEnvironment(simulator)
        showSimulationSheet()
        #else
        
        scanner?.invalidate()
        scanner = CardScanner { (result) in
            switch result {
            case .pending(let card):
                self.viewModel.setWalletInfoLoading(true)
                self.viewModel.doubleScanHintLabel.isHidden = false
                
                self.cardDetails = card
                self.setupWithCardDetails(pending: true)
            case .success(let card):
                self.cardDetails = card
                self.setupWithCardDetails()
            case .readerSessionError:
                self.navigationController?.popViewController(animated: true)
            case .locked:
                self.handleCardParserLockedCard()
            case .tlvError:
                self.handleCardParserWrongTLV()
            case .nonGenuineCard(let card):
                self.cardDetails = card
                self.setupWithCardDetails()
                self.handleNonGenuineTangemCard(card)
            }
        }
        
        scanner?.initiateScan()
        #endif
    }
    
    @IBAction func moreButtonPressed(_ sender: Any) {
        guard let cardDetails = cardDetails, let viewController = self.storyboard?.instantiateViewController(withIdentifier: "CardMoreViewController") as? CardMoreViewController else {
            return
        }
        
        var cardChallenge: String? = nil
        if let challenge = cardDetails.challenge, let saltValue = cardDetails.salt {
            let cardChallenge1 = String(challenge.prefix(3))
            let cardChallenge2 = String(challenge[challenge.index(challenge.endIndex,offsetBy:-3)...])
            let cardChallenge3 = String(saltValue.prefix(3))
            let cardChallenge4 = String(saltValue[saltValue.index(saltValue.endIndex,offsetBy:-3)...])
            cardChallenge = [cardChallenge1, cardChallenge2, cardChallenge3, cardChallenge4].joined(separator: " ")
        }
        
        var verificationChallenge: String? = nil
        if let challenge = cardDetails.verificationChallenge, let saltValue = cardDetails.verificationSalt {
            let cardChallenge1 = String(challenge.prefix(3))
            let cardChallenge2 = String(challenge[challenge.index(challenge.endIndex,offsetBy:-3)...])
            let cardChallenge3 = String(saltValue.prefix(3))
            let cardChallenge4 = String(saltValue[saltValue.index(saltValue.endIndex,offsetBy:-3)...])
            verificationChallenge = [cardChallenge1, cardChallenge2, cardChallenge3, cardChallenge4].joined(separator: " ")
        }
        
        let strings = ["Issuer: \(cardDetails.issuer)",
            "Manufacturer: \(cardDetails.issuer)",
            "API node: \(cardDetails.node)",
            "Challenge 1: \(cardChallenge ?? "N\\A")",
            "Challenge 2: \(verificationChallenge ?? "N\\A")",
            "Signature: \(isBalanceVerified ? "passed" : "not passed")",
            "Authenticity: attested",
            "Firmware: \(cardDetails.firmware)",
            "Registration date: \(cardDetails.manufactureDateTime)",
            "Serial: \(cardDetails.cardID)",
            "Remaining signatures: \(cardDetails.remainingSignatures)"]
        viewController.contentText = strings.joined(separator: "\n")
        
        let presentationController = CustomPresentationController(presentedViewController: viewController, presenting: self)
        self.customPresentationController = presentationController
        viewController.preferredContentSize = CGSize(width: self.view.bounds.width, height: min(478, self.view.frame.height - 200))
        viewController.transitioningDelegate = presentationController
        self.present(viewController, animated: true, completion: nil)
    }
    
}

extension CardDetailsViewController {
    
    func handleCardParserWrongTLV() {
        let validationAlert = UIAlertController(title: "Error", message: "Failed to parse data received from the banknote", preferredStyle: .alert)
        validationAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(validationAlert, animated: true, completion: nil)
    }
    
    func handleCardParserLockedCard() {
        print("Card is locked, two first bytes are equal 0x6A86")
        let validationAlert = UIAlertController(title: "Info", message: "This app can’t read protected Tangem banknotes", preferredStyle: .alert)
        validationAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(validationAlert, animated: true, completion: nil)
    }
    
    func handleNonGenuineTangemCard(_ card: Card) {
        let validationAlert = UIAlertController(title: "Error", message: "It is not a genuine Tangem card or your iPhone does not allow to attest the card", preferredStyle: .alert)
        validationAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(validationAlert, animated: true, completion: nil)
    }

}

extension CardDetailsViewController: LoadViewControllerDelegate {
    
    func loadViewControllerDidCallShowQRCode(_ controller: LoadViewController) {
        self.dismiss(animated: true) {
            guard let viewController = self.storyboard?.instantiateViewController(withIdentifier: "QRCodeViewController") as? QRCodeViewController else {
                return
            }
            
            viewController.cardDetails = self.cardDetails
            
            let presentationController = CustomPresentationController(presentedViewController: viewController, presenting: self)
            self.customPresentationController = presentationController
            viewController.preferredContentSize = CGSize(width: self.view.bounds.width, height: 441)
            viewController.transitioningDelegate = presentationController
            self.present(viewController, animated: true, completion: nil)
        }
    }
    
}

