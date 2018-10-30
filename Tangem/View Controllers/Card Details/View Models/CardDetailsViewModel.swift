//
//  CardDetailsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import UIKit

class CardDetailsViewModel: NSObject {
    
    // MARK: Image Views
    
    @IBOutlet weak var qrCodeImageView: UIImageView!
    @IBOutlet weak var balanceVefificationIconImageView: UIImageView!
    @IBOutlet weak var cardImageView: UIImageView!
    
    // MARK: Labels
    
    @IBOutlet weak var balanceLabel: UILabel! {
        didSet {
            balanceLabel.font = UIFont.tgm_maaxFontWith(size: 24, weight: .medium)
        }
    }
    @IBOutlet weak var balanceVerificationLabel: UILabel! {
        didSet {
            balanceVerificationLabel.font = UIFont.tgm_maaxFontWith(size: 14, weight: .medium)
        }
    }
    
    @IBOutlet weak var walletBlockchainLabel: UILabel! {
        didSet {
            walletBlockchainLabel.font = UIFont.tgm_maaxFontWith(size: 14, weight: .medium)
        }
    }
    
    @IBOutlet weak var doubleScanHintLabel: UILabel! {
        didSet {
            doubleScanHintLabel.font = UIFont.tgm_maaxFontWith(size: 17, weight: .medium)
            doubleScanHintLabel.textColor = UIColor.tgm_red()
        }
    }
    //    [REDACTED_USERNAME] weak var networkSafetyDescriptionLabel: UILabel! {
//        didSet {
//            networkSafetyDescriptionLabel.font = UIFont.tgm_maaxFontWith(size: 12)
//        }
//    }
    
    @IBOutlet weak var walletAddressLabel: UILabel! {
        didSet {
            walletAddressLabel.font = UIFont.tgm_maaxFontWith(size: 14, weight: .medium)
        }
    }
    
    // MARK: Buttons
    
    @IBOutlet weak var buttonsAvailabilityView: UIView!
    
    @IBOutlet weak var loadButton: UIButton! {
        didSet {
            loadButton.layer.cornerRadius = 30.0
            loadButton.titleLabel?.font = UIFont.tgm_sairaFontWith(size: 20, weight: .bold)
            
            loadButton.layer.shadowRadius = 5.0
            loadButton.layer.shadowOffset = CGSize(width: 0, height: 5)
            loadButton.layer.shadowColor = UIColor.black.cgColor
            loadButton.layer.shadowOpacity = 0.08
        }
    }
    
    @IBOutlet weak var extractButton: UIButton! {
        didSet {
            extractButton.layer.cornerRadius = 30.0
            extractButton.titleLabel?.font = UIFont.tgm_sairaFontWith(size: 20, weight: .bold)
            
            extractButton.layer.shadowRadius = 5.0
            extractButton.layer.shadowOffset = CGSize(width: 0, height: 5)
            extractButton.layer.shadowColor = UIColor.black.cgColor
            extractButton.layer.shadowOpacity = 0.08
        }
    }
    
    @IBOutlet weak var scanButton: UIButton! {
        didSet {
            scanButton.titleLabel?.font = UIFont.tgm_maaxFontWith(size: 16, weight: .medium)
        }
    }
    
    @IBOutlet weak var moreButton: UIButton! {
        didSet {
            moreButton.titleLabel?.font = UIFont.tgm_maaxFontWith(size: 16, weight: .medium)
            moreButton.setTitleColor(UIColor.lightGray, for: .disabled)
        }
    }
    
    @IBOutlet weak var exploreButton: UIButton! {
        didSet {
            exploreButton.titleLabel?.font = UIFont.tgm_sairaFontWith(size: 20, weight: .bold)
            exploreButton.setTitleColor(UIColor.lightGray, for: .disabled)
        }
    }
    
    @IBOutlet weak var copyButton: UIButton! {
        didSet {
            copyButton.titleLabel?.font = UIFont.tgm_sairaFontWith(size: 20, weight: .bold)
            copyButton.setTitleColor(UIColor.lightGray, for: .disabled)
        }
    }
    
    // MARK: Other
    
    @IBOutlet weak var balanceVerificationActivityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var cardWalletInfoView: UIView!
    @IBOutlet weak var cardWalletInfoLoadingView: UIView!
    @IBOutlet weak var qrCodeContainerView: UIView!
}

extension CardDetailsViewModel {
    
    func setWalletInfoLoading(_ loading: Bool) {
        UIView.animate(withDuration: 0.1) {
            self.cardWalletInfoView.isHidden = loading
            self.cardWalletInfoLoadingView.isHidden = !loading
        }
    }
    
    func updateNetworkSafetyDescription(_ text: String) {
//        let paragraphStyle = paragraphStyleWith(lineSpacingChange: 8.0)
//        let attributedText = NSAttributedString(string: text, attributes: [NSAttributedStringKey.paragraphStyle : paragraphStyle,
//                                                                           NSAttributedStringKey.kern : 0.75])
//        networkSafetyDescriptionLabel.attributedText = attributedText
    }
    
    func updateWalletAddress(_ text: String) {
        let paragraphStyle = paragraphStyleWith(lineSpacingChange: 5.0)
        let attributedText = NSAttributedString(string: text, attributes: [NSAttributedStringKey.paragraphStyle : paragraphStyle,
                                                                           NSAttributedStringKey.kern : 0.88])
        walletAddressLabel.attributedText = attributedText
    }
    
    func updateWalletBalanceIsBeingVerified() {
        let text = "Verifying in blockchain..."
        let attributedText = NSAttributedString(string: text, attributes: [NSAttributedStringKey.kern : 0.88,
                                                                           NSAttributedStringKey.foregroundColor : UIColor.black])
        balanceVerificationLabel.attributedText = attributedText
    }
    
    func updateWalletBalanceVerification(_ verified: Bool) {
        let text = verified ? "Verified balance" : "Unverified balance"
        let attributedText = NSAttributedString(string: text, attributes: [NSAttributedStringKey.kern : 0.88,
                                                                           NSAttributedStringKey.foregroundColor : verified ? UIColor.tgm_green() : UIColor.tgm_red()])
        balanceVerificationLabel.attributedText = attributedText
    }
    
    func updateWalletBalanceNoWallet() {
        let attributedText = NSAttributedString(string: "No wallet", attributes: [NSAttributedStringKey.kern : 0.88,
                                                                                  NSAttributedStringKey.foregroundColor : UIColor.tgm_red()])
        balanceVerificationLabel.attributedText = attributedText
    }
    
    func updateWalletBalance(_ text: String) {
        let attributedText = NSAttributedString(string: text, attributes: [NSAttributedStringKey.kern : 0.3])
        balanceLabel.attributedText = attributedText
    }
    
    func updateBlockchainName(_ text: String) {
        let attributedText = NSAttributedString(string: text, attributes: [NSAttributedStringKey.kern : 0.88])
        walletBlockchainLabel.attributedText = attributedText
    }
    
    private func paragraphStyleWith(lineSpacingChange: CGFloat, alignment: NSTextAlignment = .center) -> NSParagraphStyle {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing += lineSpacingChange
        paragraphStyle.alignment = alignment
        
        return paragraphStyle
    }
}
