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
    weak var delegate: RemoveCardsDelegate?
    weak var signDelegate: DidSignCheckDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.separatorColor = UIColor.clear
        navigationItem.title = "Card List"
    
        if cardList.count == 0 {
             emptyView.isHidden = false
        } else {
            emptyView.isHidden = true
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

        let validCellIdentifier = "ValidTableViewCell"
        let invalidCellIdentifier = "InvalidTableViewCell"
        // Configure the cell...
        var tmpCard = cardList[indexPath.row]
        var cell:UITableViewCell
        if tmpCard.isWallet {
            cell = (tableView.dequeueReusableCell(withIdentifier: validCellIdentifier,for: indexPath) as? ValidTableViewCell)!
            
            if tmpCard.CardID != "" {
                (cell as! ValidTableViewCell).backView.backgroundColor = UIColor(red:0.3921,green:0.3921,blue:0.3921,alpha:1) //gray
                (cell as! ValidTableViewCell).cardIDLabel.text = tmpCard.CardID
                (cell as! ValidTableViewCell).blockchainLabel.text = tmpCard.Blockchain
                let address = tmpCard.Address
                let start = String(address.prefix(6))
                let end = String(address[address.index(address.endIndex,offsetBy:-6)...])
                
                (cell as! ValidTableViewCell).addressLabel.text = start + "......" + end
                let priceString = tmpCard.WalletValue
                if tmpCard.checkedBalance {
                if !priceString.containsIgnoringCase(find: "0.00") && tmpCard.error == 0 {
                    (cell as! ValidTableViewCell).backView.backgroundColor = UIColor(red:0.66737,green:0.83461,blue:0.64394,alpha:1) //green
                }
                if priceString.containsIgnoringCase(find: "0.00") && tmpCard.error == 0 {
                    (cell as! ValidTableViewCell).backView.backgroundColor = UIColor(red:0.6836,green:0.8383228,blue:0.90123188,alpha:1) //blue
                    
                }
                }
                if !tmpCard.checkedBalance {
                    tmpCard.WalletValue = "     "
                    tmpCard.USDWalletValue = "     "
                    wilBalanceThread(tmpCard,indexPath)
                }
                if tmpCard.error == 1 {
                    (cell as! ValidTableViewCell).backView.backgroundColor = UIColor(red:0.3921,green:0.3921,blue:0.3921,alpha:1) //gray
                    tmpCard.WalletValue = "-"
                    tmpCard.USDWalletValue = "-"
                    tmpCard.Node = ""
                }
                
                (cell as! ValidTableViewCell).walletValue.text = tmpCard.WalletValue + " " + tmpCard.WalletUnits
                (cell as! ValidTableViewCell).usdWallet.text = "USD " + tmpCard.USDWalletValue
                (cell as! ValidTableViewCell).link = tmpCard.Link
                if tmpCard.type == "eth" {
                    (cell as! ValidTableViewCell).logoIcon.image = UIImage(named: "Ethereum")
                }
                
            }
        } else {
           cell = (tableView.dequeueReusableCell(withIdentifier: invalidCellIdentifier,for: indexPath) as? InvalidTableViewCell)!
            if tmpCard.CardID != "" {
                (cell as! InvalidTableViewCell).cardIDLabel.text = tmpCard.CardID
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
    
    func wilBalanceThread(_ card:Card,_ indexPath:IndexPath){
        //Thread for balande getting
        DispatchQueue.global(qos: .background).async {
            
            if card.type == "eth"{
                var tmpCard = card
                BalanceService.sharedInstance.getCoinMarketInfo("ethereum") { success, error in
                    if let success = success {
                        tmpCard.mult = success
                    }
                    if let _ = error {
                        tmpCard.mult = "0"
                        tmpCard.error = 1
                    }
                    
                    if tmpCard.error == 1 {
                        tmpCard.checkedBalance = true
                        
                        //To main thread
                        DispatchQueue.main.async {
                            //In main thread
                            print("\(tmpCard.mult)")
                            print("\(tmpCard.WalletValue)")
                            print("\(tmpCard.USDWalletValue)")
                            print("\(tmpCard.error)")
                            self.didReturnInMainThread(tmpCard,indexPath)
                        }
                    }
                    
                    if tmpCard.error == 0 {
                    if card.test == "1" {
                       BalanceService.sharedInstance.getEthereumTestNet(card.EthAddress) { success, error in
                            if let success = success {
                                tmpCard.valueUInt64 = success
                            }
                            if let _ = error {
                                tmpCard.WalletValue = ""
                                tmpCard.USDWalletValue = ""
                                tmpCard.error = 1
                            }
                            let price_usd:Double = (tmpCard.mult as NSString).doubleValue
                            let wei = Double(tmpCard.valueUInt64)
                            let first = wei/1000000000000000000.0
                            tmpCard.WalletValue = String(format: "%.2f", round(first*100)/100)
                            let second = price_usd
                            let value = first*second
                            tmpCard.USDWalletValue = String(format: "%.2f", round(value*100)/100)
                            if(tmpCard.mult == "0"){
                                tmpCard.USDWalletValue = ""
                            }
                            tmpCard.checkedBalance = true
                            print("Card ETH: \(tmpCard)")
                            
                            //To main thread
                            DispatchQueue.main.async {
                                //In main thread
                                print("\(tmpCard.mult)")
                                print("\(tmpCard.WalletValue)")
                                print("\(tmpCard.USDWalletValue)")
                                print("\(tmpCard.error)")
                                self.didReturnInMainThread(tmpCard,indexPath)
                            }
                            
                        }
                    } else {
                        
                        BalanceService.sharedInstance.getEthereumMainNet(card.EthAddress) { success, error in
                            if let success = success {
                                tmpCard.valueUInt64 = success
                            }
                            if let _ = error {
                                tmpCard.WalletValue = ""
                                tmpCard.USDWalletValue = ""
                                tmpCard.error = 1
                            }
                            let price_usd:Double = (tmpCard.mult as NSString).doubleValue
                            let wei = Double(tmpCard.valueUInt64)
                            let first = wei/1000000000000000000.0
                            tmpCard.WalletValue = String(format: "%.2f", round(first*100)/100)
                            let second = price_usd
                            let value = first*second
                            tmpCard.USDWalletValue = String(format: "%.2f", round(value*100)/100)
                            if(tmpCard.mult == "0"){
                                tmpCard.USDWalletValue = ""
                            }
                            tmpCard.checkedBalance = true
                            print("Card ETH: \(tmpCard)")
                            //To main thread
                            DispatchQueue.main.async {
                                //In main thread
                                print("\(tmpCard.mult)")
                                print("\(tmpCard.WalletValue)")
                                print("\(tmpCard.USDWalletValue)")
                                print("\(tmpCard.error)")
                                self.didReturnInMainThread(tmpCard,indexPath)
                            }
                            
                            
                        }
                    }
                }
                    
                    
                }
                
                
                
                
            }
            //End of the eth logic
            if card.type == "btc"{
                var tmpCard = card
                BalanceService.sharedInstance.getCoinMarketInfo("bitcoin") { success, error in
                    if let success = success {
                        tmpCard.mult = success
                    }
                    if let _ = error {
                        tmpCard.mult = "0"
                        tmpCard.error = 1
                    }
                    
                    if tmpCard.error == 1 {
                        tmpCard.checkedBalance = true
                       
                        //To main thread
                        DispatchQueue.main.async {
                            //In main thread
                            print("\(tmpCard.mult)")
                            print("\(tmpCard.WalletValue)")
                            print("\(tmpCard.USDWalletValue)")
                            print("\(tmpCard.error)")
                            self.didReturnInMainThread(tmpCard,indexPath)
                        }
                    }
                    
                   if tmpCard.error == 0 {
                    //Place for getting balance
                    if card.test == "1" {
                        BalanceService.sharedInstance.getBitcoinTestNet(card.BtcAddressTest) { success, error in
                            if let success = success {
                                tmpCard.value = success
                            }
                            if let _ = error {
                                tmpCard.WalletValue = ""
                                tmpCard.USDWalletValue = ""
                                tmpCard.error = 1
                            }
                            //Place for calculation
                            print("Finished all balance requests.")
                            let price_usd:Double = (tmpCard.mult as NSString).doubleValue
                            let satoshi = Double(tmpCard.value)
                            let first = satoshi/100000.0
                            tmpCard.WalletValue = String(format: "%.2f", round(first*100)/100)
                            let second = price_usd/1000.0
                            let value = first*second
                            tmpCard.USDWalletValue = String(format: "%.2f", round(value*100)/100)
                            if(tmpCard.mult == "0"){
                                tmpCard.USDWalletValue = ""
                            }
                            tmpCard.checkedBalance = true
                            print("Card BTC \(tmpCard)")
                            //To main thread
                            DispatchQueue.main.async {
                                //In main thread
                                print("\(tmpCard.mult)")
                                print("\(tmpCard.WalletValue)")
                                print("\(tmpCard.USDWalletValue)")
                                print("\(tmpCard.error)")
                                self.didReturnInMainThread(tmpCard,indexPath)
                            }
                        }
                    } else {
                        BalanceService.sharedInstance.getBitcoinMain(card.BtcAddressMain) { success, error in
                            if let success = success {
                                tmpCard.value = success
                            }
                            if let _ = error {
                                tmpCard.WalletValue = ""
                                tmpCard.USDWalletValue = ""
                                tmpCard.error = 1
                            }
                            
                            print("Finished all balance requests.")
                            let price_usd:Double = (tmpCard.mult as NSString).doubleValue
                            let satoshi = Double(tmpCard.value)
                            let first = satoshi/100000.0
                            tmpCard.WalletValue = String(format: "%.2f", round(first*100)/100)
                            let second = price_usd/1000.0
                            let value = first*second
                            tmpCard.USDWalletValue = String(format: "%.2f", round(value*100)/100)
                            if(tmpCard.mult == "0"){
                                tmpCard.USDWalletValue = ""
                            }
                            tmpCard.checkedBalance = true
                            print("Card BTC \(tmpCard)")
                            //Place for calculation
                            //To main thread
                            DispatchQueue.main.async {
                                //In main thread
                                print("\(tmpCard.mult)")
                                print("\(tmpCard.WalletValue)")
                                print("\(tmpCard.USDWalletValue)")
                                print("\(tmpCard.error)")
                                self.didReturnInMainThread(tmpCard,indexPath)
                            }
                            
                        }
                    }
                    
                }
            }
                
                
            }
            //End of the btc logic
            
            
            
            
        }
        //End of the thread

        
    }
    
    func didReturnInMainThread(_ card:Card,_ indexPath:IndexPath){
        print("Thread is finished")
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
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    //MARK: actions
    
    @IBAction func cleanList(_ sender: UIBarButtonItem) {
//        for  _ in 0..<cardList.count{
//            //delayWithSeconds(1) {
//                self.cardList.remove(at: 0)
//                let indexPath = IndexPath(item: 0, section: 0)
//                self.tableView.deleteRows(at: [indexPath], with: .fade)
//            //}
//        }
        
        cardList.removeAll()
        tableView.reloadData()
        emptyView.isHidden = false
        if let delegate = delegate {
            delegate.didRemoveCards()
        }
    }
    
    //MARK: private methods
    
//    func delayWithSeconds(_ seconds: Double, completion: @escaping () -> ()) {
//        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
//            completion()
//        }
//    }
    
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
