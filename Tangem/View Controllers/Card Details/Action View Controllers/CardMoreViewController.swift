//
//  CardMoreViewController.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import UIKit
import TangemSdk

class CardMoreViewController: ModalActionViewController, DefaultErrorAlertsCapable {
    
    @IBOutlet weak var contentLabel: UITextView!
    @IBOutlet weak var titleLabel: UILabel! {
        didSet {
            titleLabel.text = Localizations.moreInfo.uppercased()
        }
    }
    
    var contentText = ""
    var onDone: (()-> Void)?
    var card: CardViewModel!
    lazy var cardManager: CardManager = {
        let manager = CardManager()
        manager.config.legacyMode = Utils().needLegacyMode
        return manager
    }()
    
    @IBOutlet weak var eraseWalletButton: UIButton! {
        didSet {
            eraseWalletButton.layer.cornerRadius = 30.0
            eraseWalletButton.titleLabel?.font = UIFont.tgm_sairaFontWith(size: 20, weight: .bold)
            
            eraseWalletButton.layer.shadowRadius = 5.0
            eraseWalletButton.layer.shadowOffset = CGSize(width: 0, height: 5)
            eraseWalletButton.layer.shadowColor = UIColor.black.cgColor
            eraseWalletButton.layer.shadowOpacity = 0.08
            eraseWalletButton.setTitle(Localizations.menuLoadedWalletEraseWallet, for: .normal)
            eraseWalletButton.setTitleColor(UIColor.lightGray, for: .disabled)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let paragraphStyle = paragraphStyleWith(lineSpacingChange: 10.0, alignment: .left)
        let attributedText = NSAttributedString(string: contentText, attributes: [NSAttributedStringKey.paragraphStyle : paragraphStyle,
                                                                                  NSAttributedStringKey.kern : 1.12,
                                                                                  NSAttributedStringKey.font : UIFont.systemFont(ofSize: 17, weight: .regular)
        
        
])
        eraseWalletButton.isEnabled = !card.productMask.contains(.card) && card.hasEmptyWallet && !card.hasPendingTransactions && ( card.isBalanceVerified || (!card.isBalanceVerified && !card.hasAccount))
        contentLabel.attributedText = attributedText
    }
    
    private func paragraphStyleWith(lineSpacingChange: CGFloat, alignment: NSTextAlignment = .center) -> NSParagraphStyle {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing += lineSpacingChange
        paragraphStyle.alignment = alignment
        return paragraphStyle
    }
    
    @IBAction func eraseTapped(_ sender: Any) {
        if #available(iOS 13.0, *) {
            eraseWalletButton.showActivityIndicator()
            cardManager.purgeWallet(cardId: card!.cardID) {[unowned self] taskResponse in
                switch taskResponse {
                case .event(let purgeWalletResponse):
                    self.card.setupWallet(status: purgeWalletResponse.status, walletPublicKey: nil)
                case .completion(let error):
                    self.eraseWalletButton.hideActivityIndicator()
                    if let error = error {
                        if !error.isUserCancelled {
                            Analytics.log(error: error)
                            self.handleGenericError(error)
                        }
                    } else {
                        self.onDone?()
                        self.dismiss(animated: true, completion: nil)
                    }
                }
            }
        } else {
            self.handleGenericError(Localizations.disclamerNoWalletCreation)
        }
    }    
}
