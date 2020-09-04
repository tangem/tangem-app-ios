//
//  ViewController.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import UIKit
import TangemSdk

class ReaderViewController: UIViewController, DefaultErrorAlertsCapable {
    var customPresentationController: CustomPresentationController?
    var isAppLaunched = false
    
    @available(iOS 13.0, *)
    lazy var tangemSdk: TangemSdk = {
        let sdk = TangemSdk()
        sdk.config.legacyMode = Utils().needLegacyMode
        return sdk
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if isAppLaunched {
            self.isAppLaunched = false
            scanButtonPressed(self)
        } else {
            handleIOS12()
        }
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
        UIApplication.shared.open(URL(string: "https://shop.tangem.com/?afmc=1i&utm_campaign=1i&utm_source=leaddyno&utm_medium=affiliate")!, options: [:], completionHandler: nil)
    }
    
    @IBAction func scanButtonPressed(_ sender: Any) {
        Analytics.log(event: .readyToScan)
        card = nil
        hintLabel.text = Localizations.readerHintScan
        scanButton.showActivityIndicator()
        if #available(iOS 13.0, *) {
            let task = ScanTaskExtended()

        tangemSdk.startSession(with: task, cardId: nil) {[weak self] result in
             guard let self = self else { return }
            
            self.scanButton.hideActivityIndicator()
            self.hintLabel.text = Localizations.readerHintDefault
            switch result {
            case .success(let response):
                self.card = CardViewModel(response.card)
                Analytics.logScan(card: response.card)
                self.card?.genuinityState = .genuine
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                   self.isAppLaunched = true
                }
                
                guard self.card!.isBlockchainKnown else {
                    self.handleUnknownBlockchainCard()
                    return
                }
                
                guard !self.card!.productMask.contains(.idCard) else {
                    self.card!.issuerExtraData = response.issuerExtraData
                    (self.card!.cardEngine as! ETHIdEngine).setupAddress()
                    UIApplication.navigationManager().showIdDetailsViewControllerWith(cardDetails: self.card!)
                    return
                }
                
                UIApplication.navigationManager().showCardDetailsViewControllerWith(cardDetails: self.card!)
                case .failure(let error):
                    if !error.isUserCancelled {
                        task.trace?.stop()
                        Analytics.log(error: error)
//                        if case .verificationFailed = error {
//                            self.handleNonGenuineTangemCard() {}
//                        } else {
                            self.handleGenericError(error)
                        //}
                    } else {
                        task.trace?.stop()
                    }
                }
            }
        } else {
            // Fallback on earlier versions
        }
    }
    
}
