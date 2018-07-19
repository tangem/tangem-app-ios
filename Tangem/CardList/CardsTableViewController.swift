//
//  CardsTableViewController.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Yulia Moskaleva. All rights reserved.
//

import UIKit

class CardsTableViewController: UITableViewController,DidSignCheckDelegate {
    
    var cardList = [Card]()
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var scanAgainView: UIView!
    weak var delegate: RemoveCardsDelegate?
    weak var signDelegate: DidSignCheckDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.separatorColor = UIColor.clear
        navigationItem.title = "Card List"
    
        if cardList.count == 0 {
             emptyView.isHidden = false
             scanAgainView.isHidden = true
        } else {
            emptyView.isHidden = true
            scanAgainView.isHidden = false
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
       
        return cardList.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let grayColor = hexStringToUIColor(hex: "#bbbbcb")
        let validCellIdentifier = "ValidTableViewCell"
        let invalidCellIdentifier = "InvalidTableViewCell"
        // Configure the cell...
        var tmpCard = cardList[indexPath.row]
        var cell:UITableViewCell
        if tmpCard.isWallet {
            cell = (tableView.dequeueReusableCell(withIdentifier: validCellIdentifier,for: indexPath) as? ValidTableViewCell)!
            
            if tmpCard.cardID != "" {
                (cell as! ValidTableViewCell).backView.backgroundColor = grayColor // UIColor(red:0.3921,green:0.3921,blue:0.3921,alpha:1) //gray
                (cell as! ValidTableViewCell).cardIDLabel.text = tmpCard.cardID
                (cell as! ValidTableViewCell).blockchainLabel.text = tmpCard.blockchain
                let address = tmpCard.address
                let start = String(address.prefix(6))
                let end = String(address[address.index(address.endIndex,offsetBy:-6)...])
                
                (cell as! ValidTableViewCell).addressLabel.text = start + "......" + end
                let priceString = tmpCard.walletValue
                if tmpCard.checkedBalance {
                if !priceString.containsIgnoringCase(find: "0.00") && tmpCard.error == 0 {
                    (cell as! ValidTableViewCell).backView.backgroundColor = UIColor(red:0.66737,green:0.83461,blue:0.64394,alpha:1) //green
                }
                if priceString.containsIgnoringCase(find: "0.00") && tmpCard.error == 0 {
                    let blueColor = hexStringToUIColor(hex: "#bcd9e5")
                    (cell as! ValidTableViewCell).backView.backgroundColor = blueColor//UIColor(red:0.6836,green:0.8383228,blue:0.90123188,alpha:1) //blue
                    
                }
                }
                if !tmpCard.checkedBalance {
                    tmpCard.walletValue = "     "
                    tmpCard.usdWalletValue = "     "
                    getBalanceInThread(tmpCard, indexPath)
                }
                if tmpCard.error == 1 {
                    (cell as! ValidTableViewCell).backView.backgroundColor = grayColor //UIColor(red:0.3921,green:0.3921,blue:0.3921,alpha:1) //gray
                    tmpCard.walletValue = "-"
                    tmpCard.usdWalletValue = "-"
                    tmpCard.node = ""
                }
                
                (cell as! ValidTableViewCell).walletValue.text = tmpCard.walletValue + " " + tmpCard.walletUnits
                (cell as! ValidTableViewCell).usdWallet.text = "USD " + tmpCard.usdWalletValue
                (cell as! ValidTableViewCell).link = tmpCard.link
                if tmpCard.type == .eth {
                    (cell as! ValidTableViewCell).logoIcon.image = UIImage(named: "Ethereum")
                }
                if tmpCard.type == .btc && !tmpCard.isTestNet {
                    (cell as! ValidTableViewCell).logoIcon.image = UIImage(named: "Bitcoin-org")
                }
                //MARK: - UI for Ribbon Cases
                switch tmpCard.ribbonCase {
                case 1:
                    (cell as! ValidTableViewCell).ribbonLabel.text = "DEVELOPER KIT"
                    (cell as! ValidTableViewCell).voidImage.isHidden = true
                case 2:
                    (cell as! ValidTableViewCell).ribbonLabel.backgroundColor = .white
                    (cell as! ValidTableViewCell).voidImage.isHidden = true
                case 3:
                    (cell as! ValidTableViewCell).ribbonLabel.backgroundColor = .red
                case 4:
                    (cell as! ValidTableViewCell).voidImage.isHidden = true
                default:
                    //Default
                    (cell as! ValidTableViewCell).ribbonLabel.isHidden = true
                    (cell as! ValidTableViewCell).voidImage.isHidden = true
                    
                }
                
            }
        } else {
           cell = (tableView.dequeueReusableCell(withIdentifier: invalidCellIdentifier,for: indexPath) as? InvalidTableViewCell)!
            if tmpCard.cardID != "" {
                (cell as! InvalidTableViewCell).cardIDLabel.text = tmpCard.cardID
                //MARK: - UI for Ribbon Cases
                switch tmpCard.ribbonCase {
                case 1:
                    (cell as! InvalidTableViewCell).ribbonLabel.text = "DEVELOPER KIT"
                    (cell as! InvalidTableViewCell).voidImage.isHidden = true
                case 2:
                    (cell as! InvalidTableViewCell).ribbonLabel.backgroundColor = .white
                    (cell as! InvalidTableViewCell).voidImage.isHidden = true
                case 3:
                    (cell as! InvalidTableViewCell).ribbonLabel.backgroundColor = .red
                case 4:
                    (cell as! InvalidTableViewCell).voidImage.isHidden = true
                default:
                    //Default
                    (cell as! InvalidTableViewCell).ribbonLabel.isHidden = true
                    (cell as! InvalidTableViewCell).voidImage.isHidden = true
                    
                }
            }
        }
        
        
        
        cell.separatorInset = UIEdgeInsets.zero
        cell.layoutMargins = UIEdgeInsets.zero
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let tmpCard = cardList[indexPath.row]
        let storyBoard = UIStoryboard(name: "Card", bundle: nil)
        let nextViewController = storyBoard.instantiateViewController(withIdentifier: "CardViewController")
        if let nextViewController = nextViewController as? CardViewController {
            nextViewController.cardDetails = tmpCard
            nextViewController.delegate = self
            nextViewController.cardRow = indexPath.row
        }

        if let owningNavigationController = navigationController{
            owningNavigationController.pushViewController(nextViewController, animated: true)
        }
        
        
    }
    
    
    
    func getBalanceInThread(_ card: Card, _ indexPath:IndexPath){
        DispatchQueue.global(qos: .background).async {
            switch card.type {
            case .btc:
                self.getBalanceBTC(card, indexPath)
            case .eth:
                self.getBalanceETH(card, indexPath)
            case .seed:
                self.getTokenBalance(card, indexPath)
            default:
                break
            }
        }
    }
    
    func didReturnInMainThread(_ card:Card,_ indexPath:IndexPath){
        cardList[indexPath.row] = card
        tableView.reloadData()
        if(card.error == 1){
            let validationAlert = UIAlertController(title: "Cannot obtain full wallet data. No connection with blockchain nodes", message: "", preferredStyle: .alert)
            validationAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(validationAlert, animated: true, completion: nil)
        }
        if let signDelegate = self.signDelegate {
            signDelegate.didBalance(cardRow:indexPath.row, card)
        }
    }
    
    //MARK: actions
    
    @IBAction func cleanList(_ sender: UIBarButtonItem) {

        cardList.removeAll()
        tableView.reloadData()
        emptyView.isHidden = false
        scanAgainView.isHidden = true
        if let delegate = delegate {
            delegate.didRemoveCards()
        }
    }
    
    //MARK: private methods
    
    
    func didCheck(cardRow:Int, checkResult:Bool){
        cardList[cardRow].checked = true
        cardList[cardRow].checkedResult = checkResult
        if let signDelegate = self.signDelegate {
            signDelegate.didCheck(cardRow:cardRow, checkResult:checkResult)
        }
    }
    
    func didBalance(cardRow:Int,_ card:Card){
        //Only for delegate implementation
    }
    
    func updateCard(){
        
    }

    
}

extension CardsTableViewController{
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    
        return 185.0
    }
}
