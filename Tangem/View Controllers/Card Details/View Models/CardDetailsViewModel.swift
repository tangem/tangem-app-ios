//
//  CardDetailsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import UIKit

class CardDetailsViewModel: NSObject {
    var actionButtonState: ActionButtonState = .createWallet {
        didSet {
            switch actionButtonState {
            case .claimTag:
                 actionButton?.setTitle(Localizations.loadedWalletBtnClaim, for: .normal)
            case .createWallet:
                actionButton?.setTitle(Localizations.emptyWalletBtnCreate, for: .normal)
            }
        }
    }
    
    // MARK: Image Views
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var qrCodeImageView: UIImageView!
    @IBOutlet weak var cardImageView: UIImageView!
    @IBOutlet weak var payIdButton: UIButton!
    
    // MARK: Labels
    
    @IBOutlet weak var balanceLabel: UILabel! {
        didSet {
            balanceLabel.font = UIFont.tgm_maaxFontWith(size: 20, weight: .medium)
        }
    }
    @IBOutlet weak var balanceVerificationLabel: UILabel! {
        didSet {
            balanceVerificationLabel.font = UIFont.tgm_maaxFontWith(size: 16, weight: .medium)
        }
    }
    
    @IBOutlet weak var walletBlockchainLabel: UILabel! {
        didSet {
            walletBlockchainLabel.font = UIFont.tgm_maaxFontWith(size: 18, weight: .medium)
        }
    }
    
    
    @IBOutlet weak var walletAddressLabel: UILabel! {
        didSet {
            walletAddressLabel.font = UIFont.tgm_maaxFontWith(size: 15, weight: .medium)
        }
    }
    
    // MARK: Buttons
    
    @IBOutlet weak var loadButton: UIButton! {
        didSet {
            loadButton.layer.cornerRadius = 30.0
            loadButton.titleLabel?.font = UIFont.tgm_sairaFontWith(size: 20, weight: .bold)
            
            loadButton.layer.shadowRadius = 5.0
            loadButton.layer.shadowOffset = CGSize(width: 0, height: 5)
            loadButton.layer.shadowColor = UIColor.black.cgColor
            loadButton.layer.shadowOpacity = 0.08
            loadButton.setTitle(Localizations.loadedWalletBtnLoad, for: .normal)
            loadButton.setTitleColor(UIColor.lightGray, for: .disabled)
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
            extractButton.setTitle(Localizations.loadedWalletBtnExtract, for: .normal)
            extractButton.setTitleColor(UIColor.lightGray, for: .disabled)
        }
    }
    @IBOutlet weak var actionButton: UIButton! {
        didSet {
            actionButton.layer.cornerRadius = 30.0
            actionButton.titleLabel?.font = UIFont.tgm_sairaFontWith(size: 20, weight: .bold)
            
            actionButton.layer.shadowRadius = 5.0
            actionButton.layer.shadowOffset = CGSize(width: 0, height: 5)
            actionButton.layer.shadowColor = UIColor.black.cgColor
            actionButton.layer.shadowOpacity = 0.08
            actionButton.setTitle(Localizations.emptyWalletBtnCreate, for: .normal)
            actionButton.setTitleColor(UIColor.lightGray, for: .disabled)
        }
    }
    
    @IBOutlet weak var scanButton: UIButton! {
        didSet {
            scanButton.titleLabel?.font = UIFont.tgm_maaxFontWith(size: 16, weight: .medium)
            scanButton.setTitle(Localizations.loadedWalletBtnNewScan, for: .normal)
        }
    }
    
    @IBOutlet weak var moreButton: UIButton! {
        didSet {
            moreButton.titleLabel?.font = UIFont.tgm_maaxFontWith(size: 16, weight: .medium)
            moreButton.setTitleColor(UIColor.lightGray, for: .disabled)
            moreButton.setTitle(Localizations.moreInfo, for: .normal)
        }
    }
    
    @IBOutlet weak var exploreButton: UIButton! {
        didSet {
            exploreButton.titleLabel?.font = UIFont.tgm_sairaFontWith(size: 20, weight: .bold)
            exploreButton.setTitleColor(UIColor.lightGray, for: .disabled)
            exploreButton.setTitle(Localizations.loadedWalletBtnExplore, for: .normal)
        }
    }
    
    @IBOutlet weak var copyButton: UIButton! {
        didSet {
            copyButton.titleLabel?.font = UIFont.tgm_sairaFontWith(size: 20, weight: .bold)
            copyButton.setTitleColor(UIColor.lightGray, for: .disabled)
            copyButton.setTitle(Localizations.loadedWalletBtnCopy, for: .normal)
        }
    }
    
    // MARK: Other
    
    @IBOutlet weak var cardWalletInfoView: UIView!

    @IBOutlet weak var qrCodeContainerView: UIView!
}

extension CardDetailsViewModel {
    
    func setSubstitutionInfoLoading(_ isLoading: Bool) {
        cardImageView.isHidden = isLoading
    }
    
    func setWalletInfoLoading(_ loading: Bool) {
            self.actionButton.isEnabled = !loading
            self.extractButton.isEnabled = !loading
            self.loadButton.isEnabled = !loading
        
        if !loading {
            scrollView.refreshControl?.endRefreshing()
        }
    }
    
    func updateWalletAddress(_ text: String) {
        let attributedText = NSAttributedString(string: text, attributes: [NSAttributedString.Key.kern : 0.88])
        walletAddressLabel.attributedText = attributedText
    }
    
    func updateWalletBalanceIsBeingVerified() {
//        let text = Localizations.loadedWalletVerifyingInBlockchain
//        let attributedText = NSAttributedString(string: text, attributes: [NSAttributedString.Key.kern : 0.88,
//                                                                           NSAttributedString.Key.foregroundColor : UIColor.black])
//        balanceVerificationLabel.attributedText = attributedText
    }
    
    func updateWalletBalanceVerification(_ verified: Bool, customText: String? = nil) {
        var text = verified ? Localizations.verifiedBalance: Localizations.unverifiedBalance
        if let customText = customText, !customText.isEmpty {
            text = customText
        }
        let attributedText = NSAttributedString(string: text, attributes: [NSAttributedString.Key.kern : 0.88,
                                                                           NSAttributedString.Key.foregroundColor : verified ? UIColor.tgm_green() : UIColor.tgm_red()])
        balanceVerificationLabel.attributedText = attributedText
    }
    
    func updateWalletBalanceNoWallet() {
        let string = "\(Localizations.loadedWalletNoCompatibleWallet)."
        let attributedText = NSAttributedString(string: string, attributes: [NSAttributedString.Key.kern : 0.88,
                                                                             NSAttributedString.Key.foregroundColor : UIColor.tgm_red()])
        balanceVerificationLabel.attributedText = attributedText
    }
    
    func updateWalletBalance(title: String, subtitle: String? = nil) {
        let attributedText = NSMutableAttributedString(string: title, attributes: [NSAttributedString.Key.kern : 0.3])

        if let subtitle = subtitle {
            let subtitleAttributedString = NSAttributedString(string: subtitle, 
                                                              attributes: [NSAttributedString.Key.font : UIFont.tgm_maaxFontWith(size: 16, weight: .medium)])
            attributedText.append(subtitleAttributedString)
        }        
        
        balanceLabel.attributedText = attributedText
    }
    
    func updateBlockchainName(_ text: String) {
        let attributedText = NSAttributedString(string: text, attributes: [NSAttributedString.Key.kern : 0.88])
        walletBlockchainLabel.attributedText = attributedText
    }
    
    private func paragraphStyleWith(lineSpacingChange: CGFloat, alignment: NSTextAlignment = .center) -> NSParagraphStyle {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing += lineSpacingChange
        paragraphStyle.alignment = alignment
        
        return paragraphStyle
    }
}


enum ActionButtonState {
    case claimTag
    case createWallet
}
