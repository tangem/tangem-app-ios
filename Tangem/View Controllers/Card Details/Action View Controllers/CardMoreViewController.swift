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
    lazy var tangemSdk: TangemSdk = {
        let sdk = TangemSdk()
        sdk.config.legacyMode = Utils().needLegacyMode
        return sdk
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
            tangemSdk.purgeWallet(cardId: card!.cardID) {[unowned self] result in
                self.eraseWalletButton.hideActivityIndicator()
                switch result {
                case .success(let purgeWalletResponse):
                    self.card.setupWallet(status: purgeWalletResponse.status, walletPublicKey: nil)
                    self.onDone?()
                    self.dismiss(animated: true, completion: nil)
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
