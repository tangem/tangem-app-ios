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
    
    @IBOutlet var viewModel: CardDetailsViewModel! {
        didSet {
            viewModel.onBalanceTap = updateBalance
        }
    }
    
    var card: Card?
    var isBalanceVerified = false
    var isBalanceLoading = false
    
    
    var customPresentationController: CustomPresentationController?
    
    let operationQueue = OperationQueue()
    var dispatchWorkItem: DispatchWorkItem?
    
    lazy var tangemSession: TangemSession = {
        let session = TangemSession(delegate: self)
        return session
    }()
    
    let storageManager: StorageManagerType = SecureStorageManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let card = card else {
            assertionFailure()
            return
        }
        
        setupWithCardDetails(card: card)
    }
    
    
    func updateBalance() {
        guard let card = card else {
            assertionFailure()
            return
        }
        
        guard !isBalanceLoading else {
            return
        }
        
        self.isBalanceLoading = true
        self.viewModel.setWalletInfoLoading(true)
        fetchWalletBalance(card: card)
        
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
            self.fetchWalletBalance(card: card)
            self.viewModel.cardImageView.image = card.image
        }
        self.viewModel.cardImageView.image = card.image
        operationQueue.addOperation(operation)
    }
    
    func fetchWalletBalance(card: Card) {
        
        guard card.isWallet else {
            isBalanceLoading = false
            viewModel.setWalletInfoLoading(false)
            setupBalanceNoWallet()
            return
        }
        
        let operation = card.balanceRequestOperation(onSuccess: { (card) in
            self.isBalanceLoading = false
            self.viewModel.setWalletInfoLoading(false)
            
            self.card = card
            
            if card.cardEngine.walletType == .nft {
                self.handleBalanceLoadedNFT()
            } else {
                self.handleBalanceLoaded()
            }
            
        }, onFailure: { (error) in
            self.isBalanceLoading = false
            self.viewModel.setWalletInfoLoading(false)
            self.viewModel.updateWalletBalance(title: "-- " + card.walletUnits)
            
            let validationAlert = UIAlertController(title: Localizations.generalError, message: Localizations.loadedWalletErrorObtainingBlockchainData, preferredStyle: .alert)
            validationAlert.addAction(UIAlertAction(title: Localizations.ok, style: .default, handler: nil))
            self.present(validationAlert, animated: true, completion: nil)
            self.setupBalanceVerified(false)
        })
        
        guard operation != nil else {
            isBalanceLoading = false
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
        let blockchainName = card.cardEngine.blockchainDisplayName
        let name = card.isTestBlockchain ? "\(blockchainName) \(Localizations.test)" : blockchainName
        viewModel.updateBlockchainName(name)
        viewModel.updateWalletAddress(card.address)
        
        var qrCodeResult = QRCode(card.qrCodeAddress)
        qrCodeResult?.size = viewModel.qrCodeImageView.frame.size
        viewModel.qrCodeImageView.image = qrCodeResult?.image
        
        viewModel.balanceVerificationActivityIndicator.stopAnimating()
        
        if card.cardID.starts(with: "10") {
            viewModel.loadButton.isHidden = true
            viewModel.extractButton.backgroundColor = UIColor(red: 249.0/255.0, green: 175.0/255.0, blue: 37.0/255.0, alpha: 1.0)
            viewModel.extractButton.setTitleColor(.white, for: .normal)
        } else {
            viewModel.loadButton.isHidden = false
            viewModel.extractButton.backgroundColor = .white
            viewModel.extractButton.setTitleColor(.black, for: .normal)
        }
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
            print("\(Localizations.signatureVerificationError): \(error)")
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
            balanceSubtitle = "\n+ " + "\(walletReserve) \(card.walletUnits) \(Localizations.reserve)"
        } else if let xlmEngine = card.cardEngine as? XlmEngine, let walletReserve = xlmEngine.walletReserve {
            
            if let walletTokenValue = card.walletTokenValue, let walletTokenUnits = xlmEngine.assetCode, let assetBalance = xlmEngine.assetBalance,
            assetBalance > 0 {
                 balanceTitle = "\(walletTokenValue) \(walletTokenUnits)"
                 balanceSubtitle = "\n\(card.walletValue) \(card.walletUnits) for fee + " + "\(walletReserve) \(card.walletUnits) \(Localizations.reserve)"
            } else {
                balanceTitle = card.walletValue + " " + card.walletUnits
                balanceSubtitle = "\n+ " + "\(walletReserve) \(card.walletUnits) \(Localizations.reserve)"
            }
        }
        else if let walletTokenValue = card.walletTokenValue, let walletTokenUnits = card.walletTokenUnits {
            // Tokens
            balanceTitle = walletTokenValue + " " + walletTokenUnits
            balanceSubtitle = "\n+ " + card.walletValue + " " + card.walletUnits
        } else {
            balanceTitle = card.walletValue + " " + card.walletUnits
        }
        
        self.viewModel.updateWalletBalance(title: balanceTitle, subtitle: balanceSubtitle)
        
        guard card.isBlockchainKnown else {
            setupBalanceVerified(false, customText: Localizations.alertUnknownBlockchain)
            return
        }
        
        guard !card.hasPendingTransactions else {
            setupBalanceVerified(false, customText: "\(Localizations.loadedWalletMessageWait). \(Localizations.tapToRetry)")
            return
        }
        
        if #available(iOS 13.0, *) {
            setupBalanceVerified(true, customText: card.isTestBlockchain ? Localizations.testBlockchain: nil)
        } else {            
            if card.type == .cardano {
                setupBalanceVerified(true, customText: card.isTestBlockchain ? Localizations.testBlockchain: nil)
            } else {
                verifySignature(card: card)
                setupBalanceIsBeingVerified()
            }
        }
    }
    
    func handleBalanceLoadedNFT() {
        guard let card = card else {
            assertionFailure()
            return
        }
        
        let hasBalance = NSDecimalNumber(string: card.walletTokenValue).doubleValue > 0 
        let balanceTitle = hasBalance ? Localizations.genuine : Localizations.notFound
        
        viewModel.updateWalletBalance(title: balanceTitle, subtitle: nil)
        setupBalanceVerified(hasBalance, customText: hasBalance ? Localizations.verifiedBalance : Localizations.unverifiedBalance)
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
        
        showUntrustedAlertIfNeeded()
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
        tangemSession.payload = payload
        tangemSession.start()
    }
    
    func showUntrustedAlertIfNeeded() {
        guard let card = card,
            let walletAmount = Double(card.walletValue),
            let signedHashesAmount = Int(card.signedHashes, radix: 16) else {
                return
        }
        
        let scannedCards = storageManager.stringArray(forKey: .cids) ?? []
        let cardScannedBefore = scannedCards.contains(card.cardID)
        if cardScannedBefore {
            return
        }
        
        if walletAmount > 0 && signedHashesAmount > 0 {
            DispatchQueue.main.async {
                self.handleUntrustedCard()
            }
        }
        
        let allScannedCards = scannedCards + [card.cardID]
        storageManager.set(allScannedCards, forKey: .cids)
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
        guard card.genuinityState != .pending else {
            self.isBalanceLoading = true
            self.viewModel.setWalletInfoLoading(true)
            if #available(iOS 13.0, *) {} else {
                viewModel.doubleScanHintLabel.isHidden = false
            }
            return
        }
        
        guard /*!card.isTestBlockchain &&*/ card.isBlockchainKnown else {
            handleUnknownBlockchainCard {
                self.navigationController?.popViewController(animated: true)
            }
            return
        }
        
        self.card = card
        self.setupWithCardDetails(card: card)
        
        switch card.genuinityState {
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
        case .readerSessionError(let readerError):
            handleGenericError(readerError) {
                self.navigationController?.popViewController(animated: true)
            }
        case .userCancelled:
            break
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
        let title = copied ? Localizations.copied : Localizations.loadedWalletBtnCopy
        let color = copied ? UIColor.tgm_green() : UIColor.black
        
        UIView.transition(with: viewModel.copyButton, duration: 0.1, options: .transitionCrossDissolve, animations: {
            self.viewModel.copyButton.setTitle(title.uppercased(), for: .normal)
            self.viewModel.copyButton.setTitleColor(color, for: .normal)
        }, completion: nil)
    }
    
    @IBAction func loadButtonPressed(_ sender: Any) {
        guard let card = self.card else {
            return
        }
        
        //        guard !card.cardID.starts(with: "10") else {
        //            self.handleStart2CoinLoad()
        //            return
        //        }
        
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
        if #available(iOS 13.0, *), card!.canExtract  {
            let viewController = storyboard!.instantiateViewController(withIdentifier: "ExtractViewController") as! ExtractViewController
            viewController.card = card
            viewController.onDone = { [unowned self] in
                guard let card = self.card else {
                    return
                }
                
                if card.hasPendingTransactions  {
                    self.setupBalanceVerified(false, customText: "\(Localizations.loadedWalletMessageWait). \(Localizations.tapToRetry)")
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
                        guard let self = self, !self.isBalanceVerified else {
                            return
                        }
                        
                        self.updateBalance()
                    }
                }
            }
            self.present(viewController, animated: true, completion: nil)
        } else {
            let viewController = storyboard!.instantiateViewController(withIdentifier: "ExtractPlaceholderViewController") as! ExtractPlaceholderViewController
            
            viewController.contentText = card!.canExtract ? Localizations.disclamerOldIOS :
                Localizations.disclamerOldCard
            
            let presentationController = CustomPresentationController(presentedViewController: viewController, presenting: self)
            self.customPresentationController = presentationController
            viewController.preferredContentSize = CGSize(width: self.view.bounds.width, height: 247)
            viewController.transitioningDelegate = presentationController
            self.present(viewController, animated: true, completion: nil)
        }
    }
    
    @IBAction func scanButtonPressed(_ sender: Any) {
        #if targetEnvironment(simulator)
        showSimulationSheet()
        #else
        tangemSession.start()
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
        
        var strings = ["\(Localizations.detailsCategoryIssuer): \(cardDetails.issuer)",
            "\(Localizations.detailsCategoryManufacturer): \(cardDetails.manufactureName)",
            "\(Localizations.detailsValidationNode): \(cardDetails.node)",
            "\(Localizations.challenge) 1: \(cardChallenge ?? Localizations.notAvailable)",
            "\(Localizations.challenge) 2: \(verificationChallenge ?? Localizations.notAvailable)",
            "\(Localizations.signature): \(isBalanceVerified ? Localizations.passed : Localizations.notPassed)",
            "\(Localizations.detailsCardIdentity): \(cardDetails.isAuthentic ? Localizations.detailsAttested.lowercased() : Localizations.detailsNotConfirmed)",
            "\(Localizations.detailsFirmware): \(cardDetails.firmware)",
            "\(Localizations.detailsRegistrationDate): \(cardDetails.manufactureDateTime)",
            "\(Localizations.detailsTitleCardId): \(cardDetails.cardID)",
            "\(Localizations.detailsRemainingSignatures): \(cardDetails.remainingSignatures)"]
        
        if cardDetails.isLinked {
            strings.append(Localizations.detailsLinkedCard)
        }
        
        viewController.contentText = strings.joined(separator: "\n")
        
        let presentationController = CustomPresentationController(presentedViewController: viewController, presenting: self)
        self.customPresentationController = presentationController
        viewController.preferredContentSize = CGSize(width: self.view.bounds.width, height: min(478, self.view.frame.height - 200))
        viewController.transitioningDelegate = presentationController
        self.present(viewController, animated: true, completion: nil)
    }
    
}
