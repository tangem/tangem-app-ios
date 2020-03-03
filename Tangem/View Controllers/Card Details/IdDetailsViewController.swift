//
//  IdDetailsViewController.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Smart Cash AG. All rights reserved.
//

import UIKit
import TangemKit
import TangemSdk

class IdDetailsViewController: UIViewController, DefaultErrorAlertsCapable {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var statusLabel: UILabel! {
        didSet {
            statusLabel.font = UIFont.tgm_maaxFontWith(size: 17, weight: .medium)
        }
    }
    @IBOutlet weak var idLabel: UILabel! {
        didSet {
            idLabel.font = UIFont.tgm_maaxFontWith(size: 19, weight: .medium)
        }
    }
    @IBOutlet weak var nameLabel: UILabel! {
        didSet {
            nameLabel.font = UIFont.tgm_maaxFontWith(size: 20, weight: .bold)
        }
    }
    @IBOutlet weak var dateLabel: UILabel! {
        didSet {
            dateLabel.font = UIFont.tgm_maaxFontWith(size: 17, weight: .medium)
        }
    }
    @IBOutlet weak var sexLabel: UILabel! {
        didSet {
            sexLabel.font = UIFont.tgm_maaxFontWith(size: 17, weight: .medium)
        }
    }
    @IBOutlet weak var issueNewIdButton: UIButton! {
        didSet {
            issueNewIdButton.layer.cornerRadius = 30.0
            issueNewIdButton.titleLabel?.font = UIFont.tgm_sairaFontWith(size: 20, weight: .bold)
            
            issueNewIdButton.layer.shadowRadius = 5.0
            issueNewIdButton.layer.shadowOffset = CGSize(width: 0, height: 5)
            issueNewIdButton.layer.shadowColor = UIColor.black.cgColor
            issueNewIdButton.layer.shadowOpacity = 0.08
            issueNewIdButton.setTitleColor(UIColor.lightGray, for: .disabled)
        }
    }
    
    @IBOutlet weak var newScanButton: UIButton! {
        didSet {
            newScanButton.titleLabel?.font = UIFont.tgm_maaxFontWith(size: 16, weight: .medium)
            newScanButton.setTitle(Localizations.loadedWalletBtnNewScan, for: .normal)
        }
    }
    
    @IBOutlet weak var moreButton: UIButton! {
        didSet {
            moreButton.titleLabel?.font = UIFont.tgm_maaxFontWith(size: 16, weight: .medium)
            moreButton.setTitleColor(UIColor.lightGray, for: .disabled)
            moreButton.setTitle(Localizations.moreInfo, for: .normal)
        }
    }
    
    public var card: CardViewModel!
    let operationQueue = OperationQueue()
    
    @IBAction func issueNewidTapped(_ sender: UIButton) {
        UIApplication.navigationManager().showIssueIdViewControllerWith(cardDetails: self.card!)
    }
    
    @IBAction func newScanTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func moreTapped(_ sender: Any) {
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        idLabel.text = "ID # \(card.cardID.replacingOccurrences(of: " ", with: ""))"
        guard let idData = card.getIdData() else {
            statusLabel.isHidden = true
            dateLabel.isHidden = true
            sexLabel.isHidden = true
            issueNewIdButton.isHidden = false
            nameLabel.text =  "EMPTY ID CARD"
            return
        }

        dateLabel.text = idData.birthDay
        sexLabel.text = "Sex: \(idData.gender)"
        nameLabel.text = idData.fullname
        imageView.image = UIImage(data: idData.photo)
        
        let balanceOp = card.balanceRequestOperation(onSuccess: {[weak self] card in
            self?.card = card
            let engine = card.cardEngine as! ETHIdEngine
            
            self?.statusLabel.textColor = engine.hasApprovalTx ?  UIColor.tgm_green() : UIColor.tgm_red()
            self?.statusLabel.text = engine.hasApprovalTx ?  "Verified" : "Not registered"
        }) {[weak self] error in
            let validationAlert = UIAlertController(title: Localizations.generalError, message: Localizations.loadedWalletErrorObtainingBlockchainData, preferredStyle: .alert)
            validationAlert.addAction(UIAlertAction(title: Localizations.ok, style: .default, handler: nil))
            self?.present(validationAlert, animated: true, completion: nil)
            self?.statusLabel.text = "Not registered"
            self?.statusLabel.textColor = UIColor.tgm_red()
        }
        operationQueue.addOperation(balanceOp!)
    }
}
