//
//  CardDetailsViewController.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import UIKit
import QRCode
import CryptoSwift
import TangemSdk

class CardDetailsViewController: UIViewController, DefaultErrorAlertsCapable, UIScrollViewDelegate {
    
    @available(iOS 13.0, *)
    lazy var tangemSdk: TangemSdk = {
        let sdk = TangemSdk()
        sdk.config.legacyMode = Utils().needLegacyMode
        return sdk
    }()
    
    @IBOutlet var viewModel: CardDetailsViewModel!
    
    var card: CardViewModel?
    var isBalanceVerified = false
    var isBalanceLoading = false
    var latestTxDate: Date?
    var customPresentationController: CustomPresentationController?
    
    let operationQueue = OperationQueue()
    var dispatchWorkItem: DispatchWorkItem?
    
    let storageManager: StorageManagerType = SecureStorageManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        viewModel.scrollView.refreshControl = UIRefreshControl()
        viewModel.scrollView.delegate = self
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if let refreshing = scrollView.refreshControl?.isRefreshing, refreshing == true {
            updateBalance()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let card = card else {
            assertionFailure()
            return
        }
        
        setupWithCardDetails(card: card)
    }
    
    @objc func applicationWillEnterForeground() {
        if let card = card {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.isBalanceLoading = true
                self.fetchWalletBalance(card: card)
            }
        }
    }
    
    func updateBalance(forceUnverifyed: Bool = false) {
        guard let card = card else {
            assertionFailure()
            return
        }
        
        guard !isBalanceLoading else {
            self.viewModel.setWalletInfoLoading(true)
            return
        }
        
        self.isBalanceLoading = true
        self.viewModel.setWalletInfoLoading(true)
        fetchWalletBalance(card: card, forceUnverifyed: forceUnverifyed)
        
    }
    
    func setupWithCardDetails(card: CardViewModel) {
        setupBalanceIsBeingVerified()
        viewModel.setSubstitutionInfoLoading(true)
        viewModel.setWalletInfoLoading(true)
        fetchSubstitutionInfo(card: card)
    }
    
    func fetchSubstitutionInfo(card: CardViewModel) {
        let operation = CardSubstitutionInfoOperation(card: card) { [weak self] (card) in
            guard let self = self else {
                return
            }
            self.card = card
            self.setupUI()
            self.viewModel.cardImageView.image = card.image
            self.viewModel.setSubstitutionInfoLoading(false)
            self.fetchWalletBalance(card: card)
        }
        self.viewModel.cardImageView.image = card.image
        operationQueue.addOperation(operation)
    }
    
    func fetchWalletBalance(card: CardViewModel, forceUnverifyed: Bool = false) {
        
        guard card.isWallet else {
            isBalanceLoading = false
            viewModel.setWalletInfoLoading(false)
            setupBalanceNoWallet()
            return
        }
        let operation = card.balanceRequestOperation(onSuccess: {[unowned self] (card) in
            self.card = card
            
            if card.type == .nft {
                self.handleBalanceLoadedNFT()
            } else if card.type == .slix2 {
                self.handleBalanceLoadedSlix2()
            } else {
                self.handleBalanceLoaded(forceUnverifyed)
            }
            self.card!.hasAccount = true
            self.isBalanceLoading = false
            self.viewModel.setWalletInfoLoading(false)
            }, onFailure: { (error, title) in
                self.isBalanceLoading = false
                self.viewModel.setWalletInfoLoading(false)
                Analytics.log(error: error)
                
                let errorTitle = title ?? Localizations.generalError
                let errorMessage = error.localizedDescription
                
                let validationAlert = UIAlertController(title: errorTitle, message: errorMessage, preferredStyle: .alert)
                                  validationAlert.addAction(UIAlertAction(title: Localizations.ok, style: .default, handler: nil))
                                  self.present(validationAlert, animated: true, completion: nil)
                
//                if let msg = error as? String,
//                    msg == "Account not found" {
//                   self.card!.hasAccount = false
//                    let validationAlert = UIAlertController(title: Localizations.accountNotFound, message: Localizations.loadMoreXrpToCreateAccount, preferredStyle: .alert)
//                    validationAlert.addAction(UIAlertAction(title: Localizations.ok, style: .default, handler: nil))
//                    self.present(validationAlert, animated: true, completion: nil)
//                } else {
//                    let validationAlert = UIAlertController(title: Localizations.generalError, message: Localizations.loadedWalletErrorObtainingBlockchainData, preferredStyle: .alert)
//                    validationAlert.addAction(UIAlertAction(title: Localizations.ok, style: .default, handler: nil))
//                    self.present(validationAlert, animated: true, completion: nil)
//                }
                
                if !card.productMask.contains(.tag) {
                    self.viewModel.updateWalletBalance(title: "-- " + card.walletUnits)
                    self.setupBalanceVerified(false)
                } else {
                    self.viewModel.updateWalletBalance(title: "--")
                    self.setupBalanceVerified(false, customText: Localizations.loadedWalletErrorObtainingBlockchainData)
                }
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
    
    func handleBalanceLoaded(_ forceUnverifyed: Bool) {
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
        } else if let bnbEngine = card.cardEngine as? BinanceEngine {
            if let walletTokenValue = card.walletTokenValue, let walletTokenUnits = card.tokenSymbol, (Decimal(string: walletTokenValue) ?? 0) > 0 {
                balanceTitle = "\(walletTokenValue) \(walletTokenUnits)"
                balanceSubtitle = "\n\(card.walletValue) \(card.walletUnits) for fee"
            } else {
                balanceTitle = card.walletValue + " " + card.walletUnits
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
        
        if let latestTxDate = latestTxDate {
            let interval = Date().timeIntervalSince(latestTxDate)
            if interval > 30 {
                self.latestTxDate = nil
            } else {
                setupBalanceVerified(false, customText: "\(Localizations.loadedWalletMessageWait)")
                return
            }
        }
        
        guard !forceUnverifyed && !card.hasPendingTransactions else {
            setupBalanceVerified(false, customText: "\(Localizations.loadedWalletMessageWait)")
            return
        }
        
        setupBalanceVerified(true, customText: card.isTestBlockchain ? Localizations.testBlockchain: nil)
    }
    
    func handleBalanceLoadedNFT() {
        guard let card = card else {
            assertionFailure()
            return
        }
        
        let hasBalance = NSDecimalNumber(string: card.walletTokenValue).doubleValue > 0
        let balanceTitle = hasBalance ? Localizations.genuine : Localizations.notFound
        
        viewModel.updateWalletBalance(title: balanceTitle, subtitle: nil)
        setupBalanceVerified(hasBalance, customText: hasBalance ? Localizations.verifiedTag : Localizations.unverifiedBalance)
    }
    
    func handleBalanceLoadedSlix2() {
        guard let card = card else {
            assertionFailure()
            return
        }
        let claimer = card.cardEngine as! Claimable
        var balanceTitle = ""
        switch claimer.claimStatus {
        case .genuine:
            balanceTitle = Localizations.genuine
        case .notGenuine:
            balanceTitle = Localizations.notgenuine
        case .claimed:
            balanceTitle = Localizations.alreadyClaimed
        }
        let verifyed = claimer.claimStatus != .notGenuine
        viewModel.updateWalletBalance(title: balanceTitle, subtitle: nil)
        setupBalanceVerified(verifyed, customText: verifyed ? Localizations.verifiedTag : Localizations.unverifiedBalance)
    }
    
    func setupBalanceIsBeingVerified() {
        isBalanceVerified = false
        card?.isBalanceVerified = false
        viewModel.actionButton.isHidden = true
        viewModel.qrCodeContainerView.isHidden = true
        viewModel.walletAddressLabel.isHidden = true
        viewModel.walletBlockchainLabel.isHidden = true
        viewModel.updateWalletBalanceIsBeingVerified()
        viewModel.loadButton.isEnabled = false
        viewModel.extractButton.isEnabled = false
        viewModel.moreButton.isEnabled = false
        viewModel.scanButton.isEnabled = false
        
        viewModel.exploreButton.isEnabled = true
        viewModel.copyButton.isEnabled = true
    }
    
    func setupBalanceVerified(_ verified: Bool, customText: String? = nil) {
        isBalanceVerified = verified
        card?.isBalanceVerified = verified
        viewModel.qrCodeContainerView.isHidden = false
        viewModel.walletAddressLabel.isHidden = false
        viewModel.walletBlockchainLabel.isHidden = false
        viewModel.updateWalletBalanceVerification(verified, customText: customText)
        if let card = card, (card.productMask.contains(.note) || card.productMask.contains(.idIssuer)) && card.type != .nft {
            viewModel.loadButton.isEnabled = true
            viewModel.extractButton.isEnabled = verified && !card.hasEmptyWallet
        } else {
            viewModel.loadButton.isEnabled = false
            viewModel.extractButton.isEnabled = false
        }
        
        if let card = card, card.type == .slix2 {
            viewModel.loadButton.isHidden = true
            viewModel.extractButton.isHidden = true
            viewModel.actionButtonState = .claimTag
            viewModel.actionButton.isEnabled = false
            viewModel.actionButton.isHidden = false
        } else {
            viewModel.loadButton.isHidden = false
            viewModel.extractButton.isHidden = false
            viewModel.exploreButton.isEnabled = true
        }
        viewModel.copyButton.isEnabled = true
        viewModel.moreButton.isEnabled = true
        viewModel.scanButton.isEnabled = true
        showUntrustedAlertIfNeeded()
    }
    
    func setupBalanceNoWallet() {
        isBalanceVerified = false
        
        viewModel.updateWalletBalance(title: "--")
        viewModel.actionButtonState = .createWallet
        viewModel.updateWalletBalanceNoWallet()
        viewModel.loadButton.isEnabled = false
        viewModel.extractButton.isEnabled = false
        viewModel.loadButton.isHidden = true
        viewModel.extractButton.isHidden = true
        viewModel.actionButton.isHidden = false
        viewModel.actionButton.isEnabled = true
        viewModel.walletBlockchainLabel.isHidden = true
        viewModel.qrCodeContainerView.isHidden = true
        viewModel.walletAddressLabel.isHidden = true
        viewModel.moreButton.isEnabled = true
        viewModel.scanButton.isEnabled = true
    }
    
    func showUntrustedAlertIfNeeded() {
        guard let card = card,
            let walletAmount = Double(card.balance),
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
    
    func performClaim(password: String) {
        if let claimer = card?.cardEngine as? Claimable,
            let encryptedSignature  = card?.signArr,
            let aes = try? AES(key: Array(password.sha256Hash),
                               blockMode: CBC(iv: Array(repeating: 0, count: 16)),
                               padding: .noPadding),
            let decryptedSignature = try? aes.decrypt(encryptedSignature)
        {
            claimer.claim(amount: "0.001", fee: "0.00001", targetAddress: "GAYPZMHFZERB42ONEJ4CY6ADDVTINEXMY6OZ5G6CLR4HHVKOSNJSZGMM", signature: Data(decryptedSignature)) {[weak self] result, error in
                if result {
                    self?.handleSuccess()
                    self?.viewModel.updateWalletBalance(title: Localizations.alreadyClaimed, subtitle: nil)
                } else {
                    self?.handleGenericError(error?.localizedDescription ?? "err")
                    print(error?.localizedDescription ?? "err")
                }
            }
        }
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
    
    
    @IBAction func actionButtonPressed(_ sender: Any)  {
        switch viewModel.actionButtonState {
        case .claimTag:
            let ac = UIAlertController(title: "Password", message: nil, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Claim", style: .destructive, handler: {[unowned self] action in
                if let pswd = ac.textFields?.first?.text {
                    self.performClaim(password: pswd)
                }
            }))
            
            ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
                // ac.dismiss(animated: true, completion: nil)
            }))
            
            ac.addTextField { textField in
                textField.isSecureTextEntry = true
            }
            
            self.present(ac, animated: true, completion: nil)
        case .createWallet:
            if #available(iOS 13.0, *) {
                viewModel.actionButton.showActivityIndicator()
                tangemSdk.createWallet(cardId: card!.cardID) { result in
                    self.viewModel.actionButton.hideActivityIndicator()
                    switch result {
                    case .success(let createWalletResponse):
                        self.card!.setupWallet(status: createWalletResponse.status, walletPublicKey: createWalletResponse.walletPublicKey)
                        self.setupWithCardDetails(card: self.card!)
                    case .failure(let error):
                        if !error.isUserCancelled {
                            self.handleGenericError(error)
                        }
                    }
                }
            } else {
                self.handleGenericError(Localizations.disclamerNoWalletCreation)
            }
        }
    }
    
    @available(iOS 13.0, *)
    private func showExtraction() {
        let viewController = storyboard!.instantiateViewController(withIdentifier: "ExtractViewController") as! ExtractViewController
        viewController.card = card
        viewController.onDone = { [unowned self] in
            guard let card = self.card else {
                return
            }
            
             Utils().setOldDisclamerShown()
            
            if card.type == .ducatus {
                self.latestTxDate = Date()
            }
            
            if card.hasPendingTransactions  {
                self.setupBalanceVerified(false, customText: "\(Localizations.loadedWalletMessageWait)")
                self.updateBalance(forceUnverifyed: true)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
                    guard let self = self, !self.isBalanceVerified else {
                        return
                    }
                    
                    self.updateBalance()
                }
            }
        }
        self.present(viewController, animated: true, completion: nil)
    }
    
    @IBAction func extractButtonPressed(_ sender: Any) {
        if #available(iOS 13.0, *), card!.canExtract  {
            if card!.isOldFw && NfcUtils.isPoorNfcQualityDevice && !Utils().isOldDisclamerShown {
                handleOldDevice {
                    self.showExtraction()
                }
            } else {
                showExtraction()
            }
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
        operationQueue.cancelAllOperations()
        navigationController?.popViewController(animated: true)
//        viewModel.scanButton.showActivityIndicator()
//        cardManager.scanCard {[unowned self] taskEvent in
//            switch taskEvent {
//            case .event(let scanEvent):
//                switch scanEvent {
//                case .onRead(let card):
//                    self.isBalanceLoading = true
//                    self.viewModel.setWalletInfoLoading(true)
//                    self.setupBalanceIsBeingVerified()
//                    self.viewModel.setSubstitutionInfoLoading(true)
//                    self.viewModel.actionButton.isHidden = true
//                    self.viewModel.extractButton.isHidden = false
//                    self.viewModel.loadButton.isHidden = false
//                    if #available(iOS 13.0, *) {} else {
//                        self.viewModel.doubleScanHintLabel.isHidden = false
//                    }
//                     self.card = CardViewModel(card)
//                case .onVerify(let isGenuine):
//                    self.card!.genuinityState = isGenuine ? .genuine : .nonGenuine
//                }
//            case .completion(let error):
//                self.viewModel.scanButton.hideActivityIndicator()
//                if let error = error {
//                    self.isBalanceLoading = false
//                    self.viewModel.setWalletInfoLoading(false)
//
//                    if !error.isUserCancelled {
//                        self.handleGenericError(error)
//                        return
//                    }
//
//                    if self.isBalanceLoading {
//                        self.handleNonGenuineTangemCard(self.card!) {
//                            self.setupWithCardDetails(card: self.card!)
//                        }
//                        return
//                    } else {
//                        return
//                    }
//                }
//
//                guard self.card!.status == .loaded else {
//                      self.setupWithCardDetails(card: self.card!)
//                    return
//                }
//
//                if self.card!.genuinityState == .genuine {
//
//                    guard self.card!.isBlockchainKnown else {
//                        self.handleUnknownBlockchainCard {
//                            self.navigationController?.popViewController(animated: true)
//                        }
//                        return
//                    }
//
//
//                    self.setupWithCardDetails(card: self.card!)
//
//                } else {
//                    self.handleNonGenuineTangemCard(self.card!) {
//                        self.setupWithCardDetails(card: self.card!)
//                    }
//                }
//            }
//        }
    }
    
    @IBAction func moreButtonPressed(_ sender: Any) {
        guard let cardDetails = card?.moreInfoData, let viewController = self.storyboard?.instantiateViewController(withIdentifier: "CardMoreViewController") as? CardMoreViewController else {
            return
        }
      
        viewController.contentText = cardDetails
        viewController.card = card!
        viewController.onDone = { [unowned self] in
            self.setupWithCardDetails(card: self.card!)
        }
        
        let presentationController = CustomPresentationController(presentedViewController: viewController, presenting: self)
        self.customPresentationController = presentationController
        viewController.preferredContentSize = CGSize(width: self.view.bounds.width, height: min(478, self.view.frame.height - 200))
        viewController.transitioningDelegate = presentationController
        self.present(viewController, animated: true, completion: nil)
    }
    
}
