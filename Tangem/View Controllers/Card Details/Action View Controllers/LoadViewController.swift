//
//  LoadViewController.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import Foundation
import TangemKit

protocol LoadViewControllerDelegate: class {
    func loadViewControllerDidCallShowQRCode(_ controller: LoadViewController)
}

class LoadViewController: ModalActionViewController {
    
    var cardDetails: Card?
    
    weak var delegate: LoadViewControllerDelegate?
    
    @IBOutlet weak var copyAddressButton: UIButton! {
           didSet {
               titleLabel.text = Localizations.copyAddress
           }
       }
    
    @IBOutlet weak var showQRButton: UIButton! {
        didSet {
            titleLabel.text = Localizations.loadedWalletDialogShowQr
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
    
    @IBAction func showQRButtonPressed(_ sender: Any) {
        delegate?.loadViewControllerDidCallShowQRCode(self)
    }
    
    
}
