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
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var statusLabel: UILabel! {
        didSet {
            statusLabel.font = UIFont.tgm_maaxFontWith(size: 17, weight: .medium)
        }
    }
    @IBOutlet weak var idLabel: UILabel! {
        didSet {
            idLabel.font = UIFont.tgm_maaxFontWith(size: 20, weight: .medium)
        }
    }
    @IBOutlet weak var nameLabel: UILabel! {
        didSet {
            nameLabel.font = UIFont.tgm_maaxFontWith(size: 24, weight: .medium)
        }
    }
    @IBOutlet weak var dateLabel: UILabel! {
        didSet {
            dateLabel.font = UIFont.tgm_maaxFontWith(size: 17, weight: .regular)
        }
    }
    @IBOutlet weak var sexLabel: UILabel! {
        didSet {
            sexLabel.font = UIFont.tgm_maaxFontWith(size: 17, weight: .regular)
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
    var customPresentationController: CustomPresentationController?
    let operationQueue = OperationQueue()
    
    @IBAction func issueNewidTapped(_ sender: UIButton) {
        showIssueIdViewControllerWith(cardDetails: self.card!)
    }
    
    @IBAction func newScanTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func moreTapped(_ sender: Any) {
        guard let cardDetails = card, let viewController = self.storyboard?.instantiateViewController(withIdentifier: "CardMoreViewController") as? CardMoreViewController else {
            return
        }
        
        var cardChallenge: String? = nil
        if let challenge = cardDetails.challenge, let saltValue = cardDetails.salt {
            let cardChallenge1 = String(challenge.prefix(3))
            let cardChallenge2 = String(challenge[challenge.index(challenge.endIndex,offsetBy:-3)...])
            let cardChallenge3 = String(saltValue.prefix(3))
            let cardChallenge4 = String(saltValue[saltValue.index(saltValue.endIndex,offsetBy:-3)...])
            cardChallenge = [cardChallenge1, cardChallenge2, cardChallenge3, cardChallenge4].joined(separator: " ")
        }
        
        var verificationChallenge: String? = nil
        if let challenge = cardDetails.verificationChallenge, let saltValue = cardDetails.verificationSalt {
            let cardChallenge1 = String(challenge.prefix(3))
            let cardChallenge2 = String(challenge[challenge.index(challenge.endIndex,offsetBy:-3)...])
            let cardChallenge3 = String(saltValue.prefix(3))
            let cardChallenge4 = String(saltValue[saltValue.index(saltValue.endIndex,offsetBy:-3)...])
            verificationChallenge = [cardChallenge1, cardChallenge2, cardChallenge3, cardChallenge4].joined(separator: " ")
        }
        
        var strings = ["\(Localizations.detailsCategoryIssuer): \(cardDetails.issuer)",
            "\(Localizations.detailsCategoryManufacturer): \(cardDetails.manufactureName)",
            "\(Localizations.detailsValidationNode): \(cardDetails.node)",
            "\(Localizations.detailsRegistrationDate): \(cardDetails.manufactureDateTime)"]
        
        if cardDetails.type != .slix2 {
            strings.append("\(Localizations.detailsCardIdentity): \(cardDetails.isAuthentic ? Localizations.detailsAttested.lowercased() : Localizations.detailsNotConfirmed)")
            strings.append("\(Localizations.detailsFirmware): \(cardDetails.firmware)")
            strings.append("\(Localizations.detailsRemainingSignatures): \(cardDetails.remainingSignatures)")
            strings.append("\(Localizations.detailsTitleCardId): \(cardDetails.cardID)")
            strings.append("\(Localizations.challenge) 1: \(cardChallenge ?? Localizations.notAvailable)")
            strings.append("\(Localizations.challenge) 2: \(verificationChallenge ?? Localizations.notAvailable)")
        }
        
        if cardDetails.isLinked {
            strings.append(Localizations.detailsLinkedCard)
        }
        
        viewController.contentText = strings.joined(separator: "\n")
        viewController.card = card!
        
        let presentationController = CustomPresentationController(presentedViewController: viewController, presenting: self)
        self.customPresentationController = presentationController
        viewController.preferredContentSize = CGSize(width: self.view.bounds.width, height: min(478, self.view.frame.height - 200))
        viewController.transitioningDelegate = presentationController
        self.present(viewController, animated: true, completion: nil)
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
        
        scrollView.refreshControl = UIRefreshControl()
        scrollView.refreshControl?.addTarget(self, action:
                                                     #selector(handleRefresh),
                                                     for: .valueChanged)
        
        refreshData()
    }
    
    func refreshData() {
        scrollView.refreshControl?.beginRefreshing()
        let balanceOp = card.balanceRequestOperation(onSuccess: {[weak self] card in
            self?.card = card
            self?.scrollView.refreshControl?.endRefreshing()
            let engine = card.cardEngine as! ETHIdEngine
            
            self?.statusLabel.textColor = engine.hasApprovalTx ?  UIColor.tgm_green() : UIColor.tgm_red()
            self?.statusLabel.text = engine.hasApprovalTx ?  "Verified" : "Not registered"
        }) {[weak self] _,_ in
            self?.scrollView.refreshControl?.endRefreshing()
            let validationAlert = UIAlertController(title: Localizations.generalError, message: Localizations.loadedWalletErrorObtainingBlockchainData, preferredStyle: .alert)
            validationAlert.addAction(UIAlertAction(title: Localizations.ok, style: .default, handler: nil))
            self?.present(validationAlert, animated: true, completion: nil)
            self?.statusLabel.text = "Not registered"
            self?.statusLabel.textColor = UIColor.tgm_red()
        }
        operationQueue.addOperation(balanceOp!)
    }
    
    func showIssueIdViewControllerWith(cardDetails: CardViewModel) {
        let storyBoard = UIStoryboard(name: "Card", bundle: nil)
        if #available(iOS 13.0, *) {
            guard let cardDetailsViewController = storyBoard.instantiateViewController(withIdentifier: "IssueIdViewController") as? IssueIdViewController else {
                return
            }
            
            cardDetailsViewController.card = cardDetails
            self.present(cardDetailsViewController, animated: true, completion: nil)
            
        }
    }
    
    @objc func handleRefresh() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
           self.scrollView.refreshControl?.endRefreshing()
        }
    }
}
