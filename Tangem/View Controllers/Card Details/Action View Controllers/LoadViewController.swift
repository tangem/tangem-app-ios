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
    
    var payIdProvider: PayIdProvider? {
        return cardDetails?.cardEngine as? PayIdProvider
    }
    var isCreating = false
    @IBOutlet weak var payIdView: UIView!
    @IBOutlet weak var createPayIdView: UIView!
    @IBOutlet weak var payIdText: UITextField!
    @IBOutlet weak var btnCreatePayId: UIButton!  {
        didSet {
            btnCreatePayId.layer.cornerRadius = 30.0
            btnCreatePayId.titleLabel?.font = UIFont.tgm_sairaFontWith(size: 20, weight: .bold)
            
            btnCreatePayId.layer.shadowRadius = 5.0
            btnCreatePayId.layer.shadowOffset = CGSize(width: 0, height: 5)
            btnCreatePayId.layer.shadowColor = UIColor.black.cgColor
            btnCreatePayId.layer.shadowOpacity = 0.08
            btnCreatePayId.setTitleColor(UIColor.lightGray, for: .disabled)
        }
    }
    @IBOutlet weak var showPayIdView: UIView!
    weak var delegate: LoadViewControllerDelegate?
    
    @IBOutlet weak var btnCopyPayId: UIButton!  {
           didSet {
               btnCopyPayId.layer.cornerRadius = 30.0
               btnCopyPayId.titleLabel?.font = UIFont.tgm_sairaFontWith(size: 20, weight: .bold)
               
               btnCopyPayId.layer.shadowRadius = 5.0
               btnCopyPayId.layer.shadowOffset = CGSize(width: 0, height: 5)
               btnCopyPayId.layer.shadowColor = UIColor.black.cgColor
               btnCopyPayId.layer.shadowOpacity = 0.08
               btnCopyPayId.setTitleColor(UIColor.lightGray, for: .disabled)
           }
       }
    @IBOutlet weak var lblPayId: UILabel!
    @IBOutlet weak var copyAddressButton: UIButton! {
        didSet {
            copyAddressButton.setTitle(Localizations.copyAddress, for: .normal) 
        }
    }
    
    @IBOutlet weak var showQRButton: UIButton! {
        didSet {
            showQRButton.setTitle(Localizations.loadedWalletDialogShowQr, for: .normal)
            showQRButton.layer.cornerRadius = 30.0
            showQRButton.titleLabel?.font = UIFont.tgm_sairaFontWith(size: 20, weight: .bold)
            
            showQRButton.layer.shadowRadius = 5.0
            showQRButton.layer.shadowOffset = CGSize(width: 0, height: 5)
            showQRButton.layer.shadowColor = UIColor.black.cgColor
            showQRButton.layer.shadowOpacity = 0.08
            showQRButton.setTitleColor(UIColor.lightGray, for: .disabled)
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
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let payIdProvider = payIdProvider, let cid = cardDetails?.cardModel.cardId,
            let cardPublicKey = cardDetails?.cardModel.cardPublicKey  {
            payIdView.isHidden = false
            payIdProvider.loadPayId(cid: cid, key: cardPublicKey) {[weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success(let payIdString):
                    if let payIdString = payIdString {
                        self.lblPayId.text = payIdString
                        self.showPayIdView.isHidden = false
                    } else {
                        self.createPayIdView.isHidden = false
                        return
                    }
                case .failure(let error):
                    self.handleGenericError(error)
                    self.payIdView.isHidden = true
                }
            }
        }
    }
    
    @IBAction func createPayIdTapped(_ sender: Any) {
        guard !isCreating else {
            return
        }
        
        guard let payIdString = payIdText.text,
            !payIdString.isEmpty,
            let cid = cardDetails?.cardModel.cardId,
            let address = cardDetails?.cardEngine.walletAddress,
            let cardPublicKey = cardDetails?.cardModel.cardPublicKey else {
                return
        }
        let fullPayIdString = payIdString + "$payid.tangem.com"
        isCreating = true
        btnCreatePayId.showActivityIndicator()
        if let payIdProvider = payIdProvider {
            payIdProvider.createPayId(cid: cid, key: cardPublicKey, payId: fullPayIdString, address: address) {[weak self] result in
                guard let self = self else { return }
                switch result {
                case .success:
                    self.lblPayId.text = fullPayIdString
                    self.createPayIdView.isHidden = true
                    self.showPayIdView.isHidden = false
                case .failure(let error):
                    self.createPayIdView.isHidden = false
                    self.handleGenericError(error)
                }
                self.payIdText.resignFirstResponder()
                self.btnCreatePayId.hideActivityIndicator()
                self.isCreating = false
            }
        }
    }
    
    @IBAction func copyPayIdTapped(_ sender: Any) {
        UIPasteboard.general.string = lblPayId.text
    }
}
