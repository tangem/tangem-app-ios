//
//  ViewController.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import UIKit
import TangemKit
import TangemSdk

class ReaderViewController: UIViewController, DefaultErrorAlertsCapable {
    
    var customPresentationController: CustomPresentationController?
    
    lazy var cardManager: CardManager = {
        let manager = CardManager()
        manager.config.legacyMode = Utils().needLegacyMode
        return manager
    }()
    
    private var card: CardViewModel?
    
    @IBOutlet weak var storeTitleLabel: UILabel! {
        didSet {
            storeTitleLabel.text = Localizations.storeTitle
        }
    }
    
    @IBOutlet weak var storeSubtitleLabel: UILabel! {
        didSet {
            storeSubtitleLabel.text = Localizations.storeSubtitle
        }
    }
    
    @IBOutlet weak var warningLabel: UILabel!
    @IBOutlet weak var hintLabel: UILabel! {
        didSet {
            hintLabel.font = UIFont.tgm_maaxFontWith(size: 17.0, weight: .regular)
        }
    }
    
    @IBOutlet weak var storeView: UIView! {
        didSet {
            let recognizer = UITapGestureRecognizer(target: self, action: #selector(storeViewDidTap))
            recognizer.numberOfTouchesRequired = 1
            storeView.addGestureRecognizer(recognizer)
        }
    }
    @IBOutlet weak var infoButton: UIButton!
    @IBOutlet weak var warningLabelButton: UIButton!
    @IBOutlet weak var scanButton: UIButton! {
        didSet {
            scanButton.layer.cornerRadius = 30.0
            scanButton.titleLabel?.font = UIFont.tgm_sairaFontWith(size: 20, weight: .bold)
            scanButton.setTitle(Localizations.scanButtonTitle, for: .normal)
            scanButton.setImage(UIImage(), for: .disabled)
            scanButton.layer.shadowRadius = 5.0
            scanButton.layer.shadowOffset = CGSize(width: 0, height: 5)
            scanButton.layer.shadowColor = UIColor.black.cgColor
            scanButton.layer.shadowOpacity = 0.08
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.hintLabel.text = Localizations.readerHintDefault
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            infoButton.isHidden = true
            warningLabelButton.isHidden = true
        } else {}
        _ = {
            self.showFeatureRestrictionAlertIfNeeded()
        }()
    }
    
    // MARK: Actions
    
    @IBAction func infoButtonPressed() {
        UIView.animate(withDuration: 0.3) {
            self.infoButton.alpha = fabs(self.infoButton.alpha - 1)
            self.warningLabel.alpha = fabs(self.warningLabel.alpha - 1)
        }
    }
    @objc func storeViewDidTap(_ sender: Any) {
        UIApplication.shared.open(URL(string: "https://tangemcards.com")!, options: [:], completionHandler: nil)
    }
    
    @IBAction func scanButtonPressed(_ sender: Any) {
        card = nil
        hintLabel.text = Localizations.readerHintScan
        scanButton.showActivityIndicator()
        let task = ScanTaskExtended()
        cardManager.runTask(task, cardId: nil) {[unowned self] taskEvent in
            switch taskEvent {
            case .event(let scanEvent):
                switch scanEvent {
                case .onRead(let card):
                    self.card = CardViewModel(card)
                case .onIssuerExtraDataRead(let extraData):
                    self.card!.issuerExtraData = extraData
                    let idData = self.card!.getIdData()
                    (self.card!.cardEngine as! ETHIdEngine).setupAddress()
                case .onVerify(let isGenuine):
                    self.card?.genuinityState = isGenuine ? .genuine : .nonGenuine
                }
            case .completion(let error):
                self.scanButton.hideActivityIndicator()
                self.hintLabel.text = Localizations.readerHintDefault
                if let error = error {
                    if !error.isUserCancelled {
                        self.handleGenericError(error)
                    }
                } else {
                    guard self.card!.isBlockchainKnown else {
                        self.handleUnknownBlockchainCard()
                        return
                    }
                    
                    guard !self.card!.productMask.contains(.card) else {
                        UIApplication.navigationManager().showIdDetailsViewControllerWith(cardDetails: self.card!)
                        return
                    }
                    
                    guard self.card!.status == .loaded else {
                        UIApplication.navigationManager().showCardDetailsViewControllerWith(cardDetails: self.card!)
                        return
                    }
                    
                    if self.card!.genuinityState == .genuine {
                        UIApplication.navigationManager().showCardDetailsViewControllerWith(cardDetails: self.card!)
                    } else {
                        self.handleNonGenuineTangemCard(self.card!) {
                            UIApplication.navigationManager().showCardDetailsViewControllerWith(cardDetails: self.card!)
                        }
                    }
                    
                }
            }
        }
    }
    
}
