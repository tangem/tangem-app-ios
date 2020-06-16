//
//  LoadViewController.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import Foundation

class CreatePayIdViewController: ModalActionViewController, DefaultErrorAlertsCapable {
    
    var cardDetails: CardViewModel?
    var onDone: (() -> Void)?
    
    var payIdProvider: PayIdManager? {
        return (cardDetails?.cardEngine as? PayIdProvider)?.payIdManager
    }
    
    var isCreating = false
    
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
    weak var delegate: LoadViewControllerDelegate?
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        payIdText.becomeFirstResponder()
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
                   UIPasteboard.general.string = fullPayIdString
                    let validationAlert = UIAlertController(title: Localizations.success, message: "PayID created successfully and copied to clipboard", preferredStyle: .alert)
                    validationAlert.addAction(UIAlertAction(title: Localizations.ok, style: .default, handler: { [weak self](_) in
                        self?.onDone?()
                        self?.dismiss(animated: true, completion: nil)
                    }))
                    self.present(validationAlert, animated: true, completion: nil)

                case .failure(let error):
                    self.handleGenericError(error)
                }
                self.payIdText.resignFirstResponder()
                self.btnCreatePayId.hideActivityIndicator()
                self.isCreating = false
            }
        }
    }
    
}
