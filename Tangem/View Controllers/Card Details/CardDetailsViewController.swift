//
//  CardDetailsViewController.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import UIKit
import QRCode
import TangemKit

class CardDetailsViewController: UIViewController, TestCardParsingCapable, DefaultErrorAlertsCapable {
    
    @IBOutlet var viewModel: CardDetailsViewModel!
    
    var card: Card?
    var isBalanceVerified = false
    
    var customPresentationController: CustomPresentationController?
    
    let operationQueue = OperationQueue()
    var dispatchWorkItem: DispatchWorkItem?
    
    var tangemSession: TangemSession?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let card = card else {
            assertionFailure()
            return
        }
        
        setupWithCardDetails(card: card)
    }
    
    func setupWithCardDetails(card: Card) {
        setupUI()
        
        guard card.genuinityState != .pending else {
            viewModel.setSubstitutionInfoLoading(true)
            return
        }
        
        viewModel.doubleScanHintLabel.isHidden = true
        fetchSubstitutionInfo(card: card)
    }
    
    func fetchSubstitutionInfo(card: Card) {
        let operation = CardSubstitutionInfoOperation(card: card) { [weak self] (card) in
            guard let self = self else {
                return
            }
            
            self.viewModel.setSubstitutionInfoLoading(false)
            
            self.card = card
            self.viewModel.cardImageView.image = card.image
            self.fetchWalletBalance(card: card)
        }
        operationQueue.addOperation(operation)
    }
    
    func fetchWalletBalance(card: Card) {
        
        guard card.isWallet else {
            viewModel.setWalletInfoLoading(false)
            setupBalanceNoWallet()
            return
        }
        
        let operation = card.balanceRequestOperation(onSuccess: { (card) in
            self.viewModel.setWalletInfoLoading(false)
            
            self.card = card
            
            if card.cardEngine.walletType == .nft {
                self.handleBalanceLoadedNFT()
            } else {
                self.handleBalanceLoaded()
            }
            
        }, onFailure: { (error) in
            self.viewModel.setWalletInfoLoading(false)
            self.viewModel.updateWalletBalance(title: "-- " + card.walletUnits)
            
            let validationAlert = UIAlertController(title: "Error", message: "Cannot obtain full wallet data", preferredStyle: .alert)
            validationAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(validationAlert, animated: true, completion: nil)
            self.setupBalanceVerified(false)
        })
        
        guard operation != nil else {
            viewModel.setWalletInfoLoading(false)
            setupBalanceNoWallet()
            assertionFailure()
            return
        }
        
        operationQueue.addOperation(operation!)
    }
    
    func setupUI() {
        guard let card = card else {
            assertionFailure()
            return
        }
        
        viewModel.updateBlockchainName(card.cardEngine.blockchainDisplayName)
        viewModel.updateWalletAddress(card.address)
        
        var qrCodeResult = QRCode(card.qrCodeAddress)
        qrCodeResult?.size = viewModel.qrCodeImageView.frame.size
        viewModel.qrCodeImageView.image = qrCodeResult?.image
        
        viewModel.balanceVerificationActivityIndicator.stopAnimating()
    }

    func verifySignature(card: Card) {
        viewModel.balanceVerificationActivityIndicator.startAnimating()
        do {
            let operation = try card.signatureVerificationOperation { (isGenuineCard) in
                self.viewModel.balanceVerificationActivityIndicator.stopAnimating()
                self.setupBalanceVerified(isGenuineCard)

                if !isGenuineCard {
                    self.handleNonGenuineTangemCard(card)
                }
            }

            operationQueue.addOperation(operation)
        } catch {
            print("Signature verification rrror: \(error)")
        }

    }
    
    func handleBalanceLoaded() {
        guard let card = card else {
            assertionFailure()
            return
        }
        
        var balanceTitle: String
        var balanceSubtitle: String? = nil
        
        if let xrpEngine = card.cardEngine as? RippleEngine, let walletReserve = xrpEngine.walletReserve {
            // Ripple reserve
            balanceTitle = card.walletValue + " " + card.walletUnits
            balanceSubtitle = "\n+ " + "\(walletReserve) \(card.walletUnits) reserve"
        } else if let walletTokenValue = card.walletTokenValue, let walletTokenUnits = card.walletTokenUnits {
            // Tokens
            balanceTitle = walletTokenValue + " " + walletTokenUnits
            balanceSubtitle = "\n+ " + card.walletValue + " " + card.walletUnits
        } else {
            balanceTitle = card.walletValue + " " + card.walletUnits
        }
        
        self.viewModel.updateWalletBalance(title: balanceTitle, subtitle: balanceSubtitle)
        
        guard !card.isTestBlockchain, card.isBlockchainKnown else {
            setupBalanceVerified(false, customText: "Unknown blockchain")
            return
        }
        
        if card.type == .cardano {
            setupBalanceVerified(true)
        } else {
            verifySignature(card: card)
            setupBalanceIsBeingVerified()
        }
    }
    
    func handleBalanceLoadedNFT() {
        guard let card = card else {
            assertionFailure()
            return
        }
        
        let hasBalance = NSDecimalNumber(string: card.walletTokenValue).doubleValue > 0 
        let balanceTitle = hasBalance ? "GENUINE" : "NOT FOUND"
        
        viewModel.updateWalletBalance(title: balanceTitle, subtitle: nil)
        setupBalanceVerified(hasBalance, customText: hasBalance ? "Verified in blockchain" : "Authencity was not verified")
    }

    func setupBalanceIsBeingVerified() {
        isBalanceVerified = false
        
        viewModel.qrCodeContainerView.isHidden = false
        viewModel.walletAddressLabel.isHidden = false
        
        viewModel.updateWalletBalanceIsBeingVerified()
        viewModel.loadButton.isEnabled = false
        viewModel.extractButton.isEnabled = false
        viewModel.buttonsAvailabilityView.isHidden = false
        
        viewModel.exploreButton.isEnabled = true
        viewModel.copyButton.isEnabled = true
    }
    
    func setupBalanceVerified(_ verified: Bool, customText: String? = nil) {
        isBalanceVerified = verified
        
        viewModel.qrCodeContainerView.isHidden = false
        viewModel.walletAddressLabel.isHidden = false
        
        viewModel.updateWalletBalanceVerification(verified, customText: customText)
        viewModel.loadButton.isEnabled = verified
        viewModel.extractButton.isEnabled = verified
        viewModel.buttonsAvailabilityView.isHidden = verified
        
        viewModel.exploreButton.isEnabled = true
        viewModel.copyButton.isEnabled = true
    }
    
    func setupBalanceNoWallet() {
        isBalanceVerified = false
        
        viewModel.updateWalletBalance(title: "--")
        
        viewModel.updateWalletBalanceNoWallet()
        viewModel.loadButton.isEnabled = false
        viewModel.extractButton.isEnabled = false
        viewModel.buttonsAvailabilityView.isHidden = false
        
        viewModel.qrCodeContainerView.isHidden = true
        viewModel.walletAddressLabel.isHidden = true
    }
    
    // MARK: Simulator parsing Operation

    func launchSimulationParsingOperationWith(payload: Data) {
        tangemSession = TangemSession(payload: payload, delegate: self)
        tangemSession?.start()
    }
    
}

extension CardDetailsViewController: LoadViewControllerDelegate {
    
    func loadViewControllerDidCallShowQRCode(_ controller: LoadViewController) {
        self.dismiss(animated: true) {
            guard let viewController = self.storyboard?.instantiateViewController(withIdentifier: "QRCodeViewController") as? QRCodeViewController else {
                return
            }
            
            viewController.cardDetails = self.card
            
            let presentationController = CustomPresentationController(presentedViewController: viewController, presenting: self)
            self.customPresentationController = presentationController
            viewController.preferredContentSize = CGSize(width: self.view.bounds.width, height: 441)
            viewController.transitioningDelegate = presentationController
            self.present(viewController, animated: true, completion: nil)
        }
    }
    
}

extension CardDetailsViewController : TangemSessionDelegate {

    func tangemSessionDidRead(card: Card) {
        self.card = card
        self.setupWithCardDetails(card: card)

        switch card.genuinityState {
        case .pending:
            self.viewModel.setWalletInfoLoading(true)
            self.viewModel.doubleScanHintLabel.isHidden = false
        case .nonGenuine:
            self.handleNonGenuineTangemCard(card)
        default:
            break
        }

    }

    func tangemSessionDidFailWith(error: TangemSessionError) {
        switch error {
        case .locked:
            handleCardParserLockedCard()
        case .payloadError:
            handleCardParserWrongTLV()
        case .readerSessionError:
            handleReaderSessionError() {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }

}

extension CardDetailsViewController {

    // MARK: Actions

    @IBAction func exploreButtonPressed(_ sender: Any) {
        if let link = card?.cardEngine.exploreLink, let url = URL(string: link) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    @IBAction func copyButtonPressed(_ sender: Any) {
        UIPasteboard.general.string = card?.address

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

        viewController.cardDetails = card
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

        tangemSession = TangemSession(delegate: self)
        tangemSession?.start()

        #endif
    }

    @IBAction func moreButtonPressed(_ sender: Any) {
        guard let cardDetails = card, let viewController = self.storyboard?.instantiateViewController(withIdentifier: "CardMoreViewController") as? CardMoreViewController else {
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
            "Authenticity: \(cardDetails.isAuthentic ? "attested" : "not attested")",
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

