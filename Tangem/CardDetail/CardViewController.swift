//
//  CardViewController.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Yulia Moskaleva. All rights reserved.
//

import UIKit
import QRCode

protocol DidSignCheckDelegate: class{
    func didCheck(cardRow:Int,checkResult:Bool)
    func didBalance(cardRow:Int,_ card:Card)
    
}
class CardViewController: UIViewController {
    @IBAction func openLinkTapped(_ sender: UIButton) {
        if let link = self.cardDetails?.Link, let url = URL(string: link) {
            UIApplication.shared.open(url,options: [:])
        }
    }
    //MARK: UI Ribbon Cases
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
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if let cardDetails = cardDetails{
            //MARK: - UI for Ribbon Cases
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
                //Default
                heightRibbonOne.constant = 0
                heightRibbonTwo.constant = 0
                scrollView.layoutIfNeeded()
            }

            
            
            blockcainLabel.text = cardDetails.Blockchain
            addressLabel.text = cardDetails.Address
            var label = "bitcoin:"
            if cardDetails.type == "eth" {
                label = "ethereum:"
            }
            let qrCodePhoto =  generateQRCode(from:label+cardDetails.Address)    //UIImage(named: "Bitcoin")
            //qrCode.image = qrCodePhoto
            
            var qrCodeResult = QRCode(label+cardDetails.Address)
            qrCodeResult?.size = CGSize(width:500,height:500)
            qrCode.image = qrCodeResult?.image
            
            issuerLabel.text = cardDetails.Issuer
            
            if cardDetails.Blockchain == "BTC"{
                serverLabel.text = "Bitcoin, hsmiths.changeip.net:8080"
            }
            cardIDLabel.text = cardDetails.CardID
            issuer2Label.text = cardDetails.Issuer
            blockcain2Label.text = cardDetails.Blockchain
            remainingLabel.text = cardDetails.RemainingSignatures
            isuuer3Label.text = cardDetails.Issuer
            firmwareLabel.text = cardDetails.Firmware
            
            registrationDateLabel.text = cardDetails.Manufacture_Date_Time
            walletValue.text = cardDetails.WalletValue + " " + cardDetails.WalletUnits
            usdWallet.text = "USD " + cardDetails.USDWalletValue
            if cardDetails.type == "eth" {
                logoIcon.image = UIImage(named: "Ethereum")
            }
            if cardDetails.type == "btc" && cardDetails.test == "0"  {
                logoIcon.image = UIImage(named: "Bitcoin-org")
            }
            serverLabel.text = cardDetails.Node
            serverLabel.textContainer.lineBreakMode = .byCharWrapping
            let challenge  = cardDetails.Challenge
            let saltValue  = cardDetails.Salt
            let cardChallenge1 = String(challenge.prefix(3))
            let cardChallenge2 = String(challenge[challenge.index(challenge.endIndex,offsetBy:-3)...])
            let cardChallenge3 = String(saltValue.prefix(3))
            let cardChallenge4 = String(saltValue[saltValue.index(saltValue.endIndex,offsetBy:-3)...])
            let cardChallenge = cardChallenge1 + "..." + cardChallenge2 + "..." + cardChallenge3 + "..." + cardChallenge4
            salt.text = cardChallenge
            
            if(cardDetails.checked){
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
                
                
                    DispatchQueue.global(qos: .background).async {
                       
                        
                        
                        
                        
                        let result = verify(saltHex:cardDetails.Salt, challengeHex:cardDetails.Challenge, signatureArr:cardDetails.signArr, publicKeyArr:cardDetails.pubArr)
                        
                        DispatchQueue.main.async {
                            if let delegate = self.delegate{
                                delegate.didCheck(cardRow: self.cardRow!,checkResult:result)
                            }
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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    // MARK: - QRCode
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
    //MARK: Action for Clipboard
    @IBAction func copyTapped(_ sender: UIButton) {
        //Copy a string to the pasteboard.
        let pasteboard = UIPasteboard.general
        pasteboard.string = cardDetails?.Address
        
        //Alert
        print("Copyed string \(String(describing: pasteboard.string))")
        let alertMsg:String = "Wallet address is copied to pasteboard!"
        let alertController = UIAlertController(title:  alertMsg, message: "", preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
}
