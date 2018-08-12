//
//  CardDetailsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 dns user. All rights reserved.
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
    
    @IBOutlet weak var networkSafetyDescriptionLabel: UILabel! {
        didSet {
            networkSafetyDescriptionLabel.font = UIFont.tgm_maaxFontWith(size: 12)
        }
    }
    
    @IBOutlet weak var walletAddressLabel: UILabel! {
        didSet {
            walletAddressLabel.font = UIFont.tgm_maaxFontWith(size: 14, weight: .medium)
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
            loadButton.layer.shadowOpacity = 0.3
        }
    }
    
    @IBOutlet weak var extractButton: UIButton! {
        didSet {
            extractButton.layer.cornerRadius = 30.0
            extractButton.titleLabel?.font = UIFont.tgm_sairaFontWith(size: 20, weight: .bold)
            
            extractButton.layer.shadowRadius = 5.0
            extractButton.layer.shadowOffset = CGSize(width: 0, height: 5)
            extractButton.layer.shadowColor = UIColor.black.cgColor
            extractButton.layer.shadowOpacity = 0.3
        }
    }
    
    @IBOutlet weak var scanButton: UIButton! {
        didSet {
            scanButton.titleLabel?.font = UIFont.tgm_maaxFontWith(size: 16, weight: .medium)
        }
    }
    
    @IBOutlet weak var settingsButton: UIButton! {
        didSet {
            settingsButton.titleLabel?.font = UIFont.tgm_maaxFontWith(size: 16, weight: .medium)
        }
    }
    
    @IBOutlet weak var exploreButton: UIButton! {
        didSet {
            exploreButton.titleLabel?.font = UIFont.tgm_sairaFontWith(size: 20, weight: .bold)
        }
    }
    
    @IBOutlet weak var copyButton: UIButton! {
        didSet {
            copyButton.titleLabel?.font = UIFont.tgm_sairaFontWith(size: 20, weight: .bold)
        }
    }
    
    // MARK: Other
    
    @IBOutlet weak var balanceVerificationActivityIndicator: UIActivityIndicatorView!
    
}
