//
//  CardViewController.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import UIKit
import QRCode

protocol DidSignCheckDelegate: class{
    
    func didCheck(cardRow: Int, checkResult: Bool)
    func didBalance(cardRow: Int, card: Card)
    
}
class OldCardViewController: UIViewController {
    
    @IBOutlet weak var loadingView: UIView!
    
    @IBOutlet weak var ribbonOne: UILabel!
    @IBOutlet weak var ribbonTwo: UILabel!
    @IBOutlet weak var heightRibbonOne: NSLayoutConstraint!
    @IBOutlet weak var heightRibbonTwo: NSLayoutConstraint!
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var salt: UILabel!
    @IBOutlet weak var qrCode: UIImageView!
    @IBOutlet weak var blockcainLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var issuerLabel: UILabel!
   
    @IBOutlet weak var serverLabel: UITextView!
    
    @IBOutlet weak var cardIDLabel: UILabel!
    @IBOutlet weak var issuer2Label: UILabel!
    @IBOutlet weak var blockcain2Label: UILabel!
    @IBOutlet weak var remainingLabel: UILabel!
    @IBOutlet weak var isuuer3Label: UILabel!
    @IBOutlet weak var firmwareLabel: UILabel!
    @IBOutlet weak var registrationDateLabel: UILabel!
    
    var cardDetails:Card?
    var cardRow:Int?
    weak var delegate: DidSignCheckDelegate?
    
    @IBOutlet weak var walletValue: UILabel!
    @IBOutlet weak var usdWallet: UILabel!
    
    @IBOutlet weak var logoIcon: UIImageView!
    
    @IBOutlet weak var incorrectLabel: UILabel!
    @IBOutlet weak var okLabel: UILabel!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.getBalance()
    }
    
    func setupUI() {
        guard let cardDetails = cardDetails else {
            return
        }
        
        switch cardDetails.ribbonCase {
        case 1:
            ribbonOne.text = "DEVELOPER KIT"
            ribbonTwo.text = "DO NOT ACCEPT"
        case 2:
            ribbonOne.text = "BANKNOTE"
            ribbonTwo.isHidden = true
            heightRibbonTwo.constant = 0
            scrollView.layoutIfNeeded()
        case 3:
            ribbonOne.text = "NON-TRANSFERABLE BANKNOTE"
            ribbonTwo.text = "DO NOT ACCEPT"
        case 4:
            ribbonOne.text = "NON-TRANSFERABLE BANKNOTE"
            ribbonTwo.text = "DO NOT ACCEPT - CHECK ELSEWHERE"
        default:
            heightRibbonOne.constant = 0
            heightRibbonTwo.constant = 0
            scrollView.layoutIfNeeded()
        }
        
        blockcainLabel.text = cardDetails.blockchain
        addressLabel.text = cardDetails.address
        
        var label = "bitcoin:"
        if cardDetails.type == .eth {
            label = "ethereum:"
        }
        
        var qrCodeResult = QRCode(label+cardDetails.address)
        qrCodeResult?.size = CGSize(width: 500, height: 500)
        qrCode.image = qrCodeResult?.image
        
        issuerLabel.text = cardDetails.issuer
        
        if cardDetails.blockchain == "BTC"{
            serverLabel.text = "Bitcoin, hsmiths.changeip.net:8080"
        }
        cardIDLabel.text = cardDetails.cardID
        issuer2Label.text = cardDetails.issuer
        blockcain2Label.text = cardDetails.blockchain
        remainingLabel.text = cardDetails.remainingSignatures
        isuuer3Label.text = cardDetails.issuer
        firmwareLabel.text = cardDetails.firmware
        
        registrationDateLabel.text = cardDetails.manufactureDateTime
        walletValue.text = cardDetails.walletValue + " " + cardDetails.walletUnits
        usdWallet.text = "USD " + cardDetails.usdWalletValue
        if cardDetails.type == .eth {
            logoIcon.image = UIImage(named: "Ethereum")
        }
        if cardDetails.type == .btc && !cardDetails.isTestNet {
            logoIcon.image = UIImage(named: "Bitcoin-org")
        }
        if cardDetails.type == .seed {
            logoIcon.image = UIImage(named: "logo-seed")
        }
        serverLabel.text = cardDetails.node
        serverLabel.textContainer.lineBreakMode = .byCharWrapping
        let challenge = cardDetails.challenge
        let saltValue = cardDetails.salt
        let cardChallenge1 = String(challenge.prefix(3))
        let cardChallenge2 = String(challenge[challenge.index(challenge.endIndex,offsetBy:-3)...])
        let cardChallenge3 = String(saltValue.prefix(3))
        let cardChallenge4 = String(saltValue[saltValue.index(saltValue.endIndex,offsetBy:-3)...])
        let cardChallenge = cardChallenge1 + "..." + cardChallenge2 + "..." + cardChallenge3 + "..." + cardChallenge4
        salt.text = cardChallenge
        
        if (cardDetails.checked) {
            if cardDetails.checkedResult {
                okLabel.text = "OK"
            } else {
                incorrectLabel.text = "Incorrect"
            }
            
        } else {
            let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
            self.okLabel.addSubview(activityIndicator)
            activityIndicator.frame = self.okLabel.bounds
            activityIndicator.startAnimating()
            
            
            // [REDACTED_TODO_COMMENT]
            DispatchQueue.global(qos: .background).async {
                
                let result = verify(saltHex:cardDetails.salt, challengeHex:cardDetails.challenge, signatureArr:cardDetails.signArr, publicKeyArr:cardDetails.pubArr)
                
                DispatchQueue.main.async {
                    activityIndicator.removeFromSuperview()
                    if result {
                        self.okLabel.text = "OK"
                    } else {
                        self.incorrectLabel.text = "Incorrect"
                    }
                }
            }
        }
    }

    func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.ascii)
        
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 3, y: 3)
            
            if let output = filter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output)
            }
        }
        
        return nil
    }
    
    func getBalance() {
        self.loadingView.isHidden = false
        
        let onResult = { (card: Card) in
            guard card.error == 0 else {
                let validationAlert = UIAlertController(title: "Error", message: "Cannot obtain full wallet data", preferredStyle: .alert)
                validationAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                    self.navigationController?.popViewController(animated: true)
                }))
                self.present(validationAlert, animated: true, completion: nil)
                return
            }
            
            self.loadingView.isHidden = true
            
            self.cardDetails = card
            self.walletValue.text = card.walletValue + " " + card.walletUnits
            self.usdWallet.text = "USD " + card.usdWalletValue
            self.setupUI()
        }
        
        DispatchQueue.global(qos: .background).async {
            guard let card = self.cardDetails else {
                return
            }
            
            switch card.type {
            case .btc:
                BalanceService.sharedInstance.getBalanceBTC(card, onResult: onResult)
            case .eth:
                BalanceService.sharedInstance.getBalanceETH(card, onResult: onResult)
            case .seed:
                BalanceService.sharedInstance.getBalanceToken(card, onResult: onResult)
            default:
                break
            }
        }
    }
    
    //MARK: Actions
    
    @IBAction func copyTapped(_ sender: UIButton) {
        let pasteboard = UIPasteboard.general
        pasteboard.string = cardDetails?.address
        
        print("Copyed string \(String(describing: pasteboard.string))")
        let alertMsg:String = "Wallet address is copied to pasteboard!"
        let alertController = UIAlertController(title:  alertMsg, message: "", preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func openLinkTapped(_ sender: UIButton) {
        if let link = self.cardDetails?.link, let url = URL(string: link) {
            UIApplication.shared.open(url,options: [:])
        }
    }
    
}
