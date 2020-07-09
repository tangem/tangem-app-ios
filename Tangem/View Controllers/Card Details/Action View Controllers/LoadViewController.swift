//
//  LoadViewController.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import Foundation

protocol LoadViewControllerDelegate: class {
    func loadViewControllerDidCallShowQRCode(_ controller: LoadViewController)
}

class LoadViewController: ModalActionViewController, DefaultErrorAlertsCapable {
    
    var cardDetails: CardViewModel?
    
    @IBOutlet weak var payIdLoadingIndicator: UIActivityIndicatorView!
    var payIdProvider: PayIdManager? {
        return (cardDetails?.cardEngine as? PayIdProvider)?.payIdManager
    }
    var isCreating = false
    @IBOutlet weak var payIdView: UIView!

    weak var delegate: LoadViewControllerDelegate?
    
    @IBOutlet weak var btnCopyPayId: UIButton!
    @IBOutlet weak var copyAddressButton: UIButton! {
        didSet {
            copyAddressButton.setTitle(Localizations.copyAddress, for: .normal) 
        }
    }
    
    @IBOutlet weak var showQRButton: UIButton! {
        didSet {
            showQRButton.setTitle(Localizations.loadedWalletDialogShowQr, for: .normal)
        }
    }
    
    @IBOutlet weak var titleLabel: UILabel! {
        didSet {
            titleLabel.text = Localizations.loadedWalletBtnLoad.uppercased()
        }
    }
    
    var dispatchWorkItem: DispatchWorkItem?
    
    @IBAction func copyAddressButtonPressed(_ sender: Any) {
        UIPasteboard.general.string = cardDetails?.address
        
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
        let title = copied ? Localizations.addressCopied : Localizations.copyAddress
        
        UIView.transition(with: copyAddressButton, duration: 0.1, options: .transitionCrossDissolve, animations: {
            self.copyAddressButton.setTitle(title, for: .normal)
        }, completion: nil)
    }
    
    func updateCopyPayIdForState(copied: Bool) {
        let title = copied ? "PayID copied" : payIdProvider?.payId ?? ""
        
        UIView.transition(with: btnCopyPayId, duration: 0.1, options: .transitionCrossDissolve, animations: {
            self.btnCopyPayId.setTitle(title, for: .normal)
        }, completion: nil)
    }
    
    @IBAction func showQRButtonPressed(_ sender: Any) {
        delegate?.loadViewControllerDidCallShowQRCode(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let payIdProvider = payIdProvider, let payId = payIdProvider.payId {
            self.btnCopyPayId.setTitle(payId, for: .normal)
            self.btnCopyPayId.isHidden = false
        }
    }
    
    @IBAction func copyPayIdTapped(_ sender: Any) {
        UIPasteboard.general.string = payIdProvider?.payId
        
        dispatchWorkItem?.cancel()
        
        updateCopyPayIdForState(copied: true)
        dispatchWorkItem = DispatchWorkItem(block: {
            self.updateCopyPayIdForState(copied: false)
        })
        
        guard let dispatchWorkItem = dispatchWorkItem else {
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1, execute: dispatchWorkItem)
    }
}
