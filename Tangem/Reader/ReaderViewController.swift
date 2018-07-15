//
//  ViewController.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Yulia Moskaleva. All rights reserved.
//

import UIKit

protocol RemoveCardsDelegate: class {
    func didRemoveCards()
}

class ReaderViewController: UIViewController, RemoveCardsDelegate, DidSignCheckDelegate {
    
    var cardList = [Card]()
    let helper = NFCHelper()
    
    lazy var cardParser: CardParser = {
       return CardParser(delegate: self)
    }()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.barTintColor = UIColor(red:0.0074375583790242672, green: 0.24186742305755615, blue: 0.4968341588973999, alpha: 1)
        
        helper.onNFCResult = onNFCResult(success:msg:)
        helper.restartSession()
    }
    
    //MARK: Private methods
    
    //MARK: Actions
    
    @IBAction func goList(_ sender: UIBarButtonItem) {
        let storyBoard = UIStoryboard(name: "Cards", bundle: nil)
        let nextViewController = storyBoard.instantiateViewController(withIdentifier: "CardsTableViewController")
        if let nextViewController = nextViewController as? CardsTableViewController {
            nextViewController.cardList = cardList
            nextViewController.delegate = self
        }
        
        if let owningNavigationController = navigationController{
            owningNavigationController.pushViewController(nextViewController, animated: true)
        }
    }
    
    
    @IBAction func readNFC(_ sender: UIButton) {
        helper.onNFCResult = onNFCResult(success:msg:)
        helper.restartSession()
        
        //For Simulator testing
        self.cardParser.parse(payload: TestData.btcWallet.rawValue)
    }
    
    func onNFCResult(success: Bool, msg: String) {
        DispatchQueue.main.async {
            guard success else {
                print("\(msg)")
                return
            }
            
            self.cardParser.parse(payload: msg)
        }
    }
    
    
    //MARK: Adding Balance
    
    func addBTCBalance(_ card:Card){
        let balanceGroup = DispatchGroup()
        
        var tmpCard = card
        
        balanceGroup.enter()
        BalanceService.sharedInstance.getCoinMarketInfo("bitcoin") { success, error in
            if let success = success {
                tmpCard.mult = success
            }
            if let _ = error {
                tmpCard.mult = "0"
                tmpCard.error = 1
            }
            
            balanceGroup.leave()
        }
        
        if card.isTestNet {
            
            balanceGroup.enter()
            BalanceService.sharedInstance.getBitcoinTestNet(card.btcAddressTest) { success, error in
                if let success = success {
                    tmpCard.value = success
                }
                if let _ = error {
                    tmpCard.walletValue = ""
                    tmpCard.usdWalletValue = ""
                    tmpCard.error = 1
                }
                balanceGroup.leave()
            }
        } else {
            
            balanceGroup.enter()
            BalanceService.sharedInstance.getBitcoinMain(card.btcAddressMain) { success, error in
                if let success = success {
                    tmpCard.value = success
                }
                if let _ = error {
                    tmpCard.walletValue = ""
                    tmpCard.usdWalletValue = ""
                    tmpCard.error = 1
                }
                balanceGroup.leave()
            }
        }
        
        
        balanceGroup.notify(queue: .main) {
            print("Finished all balance requests.")
            let price_usd:Double = (tmpCard.mult as NSString).doubleValue
            let satoshi = Double(tmpCard.value)
            let first = satoshi/100000.0
            tmpCard.walletValue = String(format: "%.2f", round(first*100)/100)
            let second = price_usd/1000.0
            let value = first*second
            tmpCard.usdWalletValue = String(format: "%.2f", round(value*100)/100)
            if(tmpCard.mult == "0"){
                 tmpCard.usdWalletValue = ""
            }
            print("Card BTC \(tmpCard)")
            self.addCardWithWallet(tmpCard)
            if(tmpCard.error == 1){
                let validationAlert = UIAlertController(title: "Cannot obtain full wallet data. No connection with blockchain nodes", message: "", preferredStyle: .alert)
                validationAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(validationAlert, animated: true, completion: nil)
            }
        }

        
    }
    
    func addETHBalance(_ card:Card){
        let balanceGroup = DispatchGroup()
        
        var tmpCard = card
        tmpCard.walletUnits = "ETH"
        tmpCard.address = card.ethAddress
        balanceGroup.enter()
        BalanceService.sharedInstance.getCoinMarketInfo("ethereum") { success, error in
            if let success = success {
                tmpCard.mult = success
            }
            if let _ = error {
                tmpCard.mult = "0"
                tmpCard.error = 1
            }
            balanceGroup.leave()
        }
        
        if card.isTestNet {
            balanceGroup.enter()
            BalanceService.sharedInstance.getEthereumTestNet(card.ethAddress) { success, error in
                    if let success = success {
                        tmpCard.valueUInt64 = success
                    }
                    if let _ = error {
                        tmpCard.walletValue = ""
                        tmpCard.usdWalletValue = ""
                        tmpCard.error = 1
                    }
                balanceGroup.leave()
            }
        } else {
            balanceGroup.enter()
            BalanceService.sharedInstance.getEthereumMainNet(card.ethAddress) { success, error in
                if let success = success {
                    tmpCard.valueUInt64 = success
                }
                if let _ = error {
                    tmpCard.walletValue = ""
                    tmpCard.usdWalletValue = ""
                    tmpCard.error = 1
                }
                balanceGroup.leave()
            }
        }
        
        balanceGroup.notify(queue: .main) {
            print("Finished all balance requests.")
            let price_usd:Double = (tmpCard.mult as NSString).doubleValue
            let wei = Double(tmpCard.valueUInt64)
            let first = wei/1000000000000000000.0
            tmpCard.walletValue = String(format: "%.2f", round(first*100)/100)
            let second = price_usd
            let value = first*second
            tmpCard.usdWalletValue = String(format: "%.2f", round(value*100)/100)
            if(tmpCard.mult == "0"){
                tmpCard.usdWalletValue = ""
            }
            print("Card ETH: \(tmpCard)")
            self.addCardWithWallet(tmpCard)
            if(tmpCard.error == 1){
                let validationAlert = UIAlertController(title: "Cannot obtain full wallet data. No connection with blockchain nodes", message: "", preferredStyle: .alert)
                validationAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(validationAlert, animated: true, completion: nil)
            }
            
        }
        
        
    }

    //MARK: Adding Cards
    func addCardWithWallet(_ card: Card){
        let storyBoard = UIStoryboard(name: "Cards", bundle: nil)
        let nextViewController = storyBoard.instantiateViewController(withIdentifier: "CardsTableViewController")
        if let nextViewController = nextViewController as? CardsTableViewController {
            if(isNewCard(card)) { cardList.append(card) }
            nextViewController.cardList = cardList
            nextViewController.delegate = self
            nextViewController.signDelegate = self
        }
        
        if let owningNavigationController = navigationController{
            owningNavigationController.pushViewController(nextViewController, animated: true)
        }
    }
    
    func addCardNoWallet(_ card: Card){
        let storyBoard = UIStoryboard(name: "Cards", bundle: nil)
        let nextViewController = storyBoard.instantiateViewController(withIdentifier: "CardsTableViewController")
        if let nextViewController = nextViewController as? CardsTableViewController {
            if(isNewCard(card)) { cardList.append(card) }
            nextViewController.cardList = cardList
            nextViewController.delegate = self
        }
        
        if let owningNavigationController = navigationController{
            owningNavigationController.pushViewController(nextViewController, animated: true)
        }
    }
    
    func addCardWallet(_ card: Card){
        //getBalanceInThread(card)
        let storyBoard = UIStoryboard(name: "Cards", bundle: nil)
        let nextViewController = storyBoard.instantiateViewController(withIdentifier: "CardsTableViewController")
        if let nextViewController = nextViewController as? CardsTableViewController {
            if(isNewCard(card)) { cardList.append(card) }
            nextViewController.cardList = cardList
            nextViewController.delegate = self
            nextViewController.signDelegate = self
        }
        
        if let owningNavigationController = navigationController{
            owningNavigationController.pushViewController(nextViewController, animated: true)
        }
    }
    
    func isNewCard(_ card:Card)->Bool{
        var new = true
        var i = 0
        for elem in cardList{
            if elem.cardID == card.cardID {
                cardList[i] = card
                cardList[i].checkedBalance = false
                new = false
            }
            i = i + 1
        }
        
        return new
    }
    
    func getBalanceInThread(_ card: Card){
        //Запускаем нитку для вычислений
        DispatchQueue.global(qos: .background).async {
            
            if card.type == .eth {
                var tmpCard = card
                BalanceService.sharedInstance.getCoinMarketInfo("ethereum") { success, error in
                    if let success = success {
                        tmpCard.mult = success
                    }
                    if let _ = error {
                        tmpCard.mult = "0"
                        tmpCard.error = 1
                    }
                    
                    if card.isTestNet {
                        BalanceService.sharedInstance.getEthereumTestNet(card.ethAddress) { success, error in
                            if let success = success {
                                tmpCard.valueUInt64 = success
                            }
                            if let _ = error {
                                tmpCard.walletValue = ""
                                tmpCard.usdWalletValue = ""
                                tmpCard.error = 1
                            }
                            let price_usd:Double = (tmpCard.mult as NSString).doubleValue
                            let wei = Double(tmpCard.valueUInt64)
                            let first = wei/1000000000000000000.0
                            tmpCard.walletValue = String(format: "%.2f", round(first*100)/100)
                            let second = price_usd
                            let value = first*second
                            tmpCard.usdWalletValue = String(format: "%.2f", round(value*100)/100)
                            if(tmpCard.mult == "0"){
                                tmpCard.usdWalletValue = ""
                            }
                            tmpCard.checkedBalance = true
                            print("Card ETH: \(tmpCard)")
                            
                            //Время возвращаться в главную ветку
                            DispatchQueue.main.async {
                                //Вернулись в главную нитку
                                print("\(tmpCard.mult)")
                                print("\(tmpCard.walletValue)")
                                print("\(tmpCard.usdWalletValue)")
                                print("\(tmpCard.error)")
                                self.didReturnInMainThread(tmpCard)
                            }
                            
                        }
                    } else {
                        
                        BalanceService.sharedInstance.getEthereumMainNet(card.ethAddress) { success, error in
                            if let success = success {
                                tmpCard.valueUInt64 = success
                            }
                            if let _ = error {
                                tmpCard.walletValue = ""
                                tmpCard.usdWalletValue = ""
                                tmpCard.error = 1
                            }
                            let price_usd:Double = (tmpCard.mult as NSString).doubleValue
                            let wei = Double(tmpCard.valueUInt64)
                            let first = wei/1000000000000000000.0
                            tmpCard.walletValue = String(format: "%.2f", round(first*100)/100)
                            let second = price_usd
                            let value = first*second
                            tmpCard.usdWalletValue = String(format: "%.2f", round(value*100)/100)
                            if(tmpCard.mult == "0"){
                                tmpCard.usdWalletValue = ""
                            }
                            tmpCard.checkedBalance = true
                            print("Card ETH: \(tmpCard)")
                            //Время возвращаться в главную ветку
                            DispatchQueue.main.async {
                                //Вернулись в главную нитку
                                print("\(tmpCard.mult)")
                                print("\(tmpCard.walletValue)")
                                print("\(tmpCard.usdWalletValue)")
                                print("\(tmpCard.error)")
                                self.didReturnInMainThread(tmpCard)
                            }
                            
                           
                        }
                    }
                    
                    
                   
                }
                
                
                
                
            }
            //End of the eth logic
            if card.type == .btc {
                 var tmpCard = card
                BalanceService.sharedInstance.getCoinMarketInfo("bitcoin") { success, error in
                    if let success = success {
                        tmpCard.mult = success
                    }
                    if let _ = error {
                        tmpCard.mult = "0"
                        tmpCard.error = 1
                    }
                    //Place for getting balance
                    if card.isTestNet {
                        BalanceService.sharedInstance.getBitcoinTestNet(card.btcAddressTest) { success, error in
                            if let success = success {
                                tmpCard.value = success
                            }
                            if let _ = error {
                                tmpCard.walletValue = ""
                                tmpCard.usdWalletValue = ""
                                tmpCard.error = 1
                            }
                            //Place for calculation
                            print("Finished all balance requests.")
                            let price_usd:Double = (tmpCard.mult as NSString).doubleValue
                            let satoshi = Double(tmpCard.value)
                            let first = satoshi/100000.0
                            tmpCard.walletValue = String(format: "%.2f", round(first*100)/100)
                            let second = price_usd/1000.0
                            let value = first*second
                            tmpCard.usdWalletValue = String(format: "%.2f", round(value*100)/100)
                            if(tmpCard.mult == "0"){
                                tmpCard.usdWalletValue = ""
                            }
                            tmpCard.checkedBalance = true
                            print("Card BTC \(tmpCard)")
                            //Время возвращаться в главную ветку
                            DispatchQueue.main.async {
                                //Вернулись в главную нитку
                                print("\(tmpCard.mult)")
                                print("\(tmpCard.walletValue)")
                                print("\(tmpCard.usdWalletValue)")
                                print("\(tmpCard.error)")
                                self.didReturnInMainThread(tmpCard)
                            }
                        }
                    } else {
                        BalanceService.sharedInstance.getBitcoinMain(card.btcAddressMain) { success, error in
                            if let success = success {
                                tmpCard.value = success
                            }
                            if let _ = error {
                                tmpCard.walletValue = ""
                                tmpCard.usdWalletValue = ""
                                tmpCard.error = 1
                            }
                            
                            print("Finished all balance requests.")
                            let price_usd:Double = (tmpCard.mult as NSString).doubleValue
                            let satoshi = Double(tmpCard.value)
                            let first = satoshi/100000.0
                            tmpCard.walletValue = String(format: "%.2f", round(first*100)/100)
                            let second = price_usd/1000.0
                            let value = first*second
                            tmpCard.usdWalletValue = String(format: "%.2f", round(value*100)/100)
                            if(tmpCard.mult == "0"){
                                tmpCard.usdWalletValue = ""
                            }
                            tmpCard.checkedBalance = true
                            print("Card BTC \(tmpCard)")//Place for calculation
                            //Время возвращаться в главную ветку
                            DispatchQueue.main.async {
                                //Вернулись в главную нитку
                                print("\(tmpCard.mult)")
                                print("\(tmpCard.walletValue)")
                                print("\(tmpCard.usdWalletValue)")
                                print("\(tmpCard.error)")
                                self.didReturnInMainThread(tmpCard)
                            }
                            
                        }
                    }
                    
                }
                
                
            }
            //End of the btc logic
            
            
            
            
        }
        //End of the thread
    }
    
    func didReturnInMainThread(_ card:Card){
        var i = 0
        for elem in cardList{
            if elem.cardID == card.cardID {
                cardList[i] = card
                break
            }
            i = i + 1
        }
        
        
        //Вызываем функцию в Card List View
        let storyBoard = UIStoryboard.init(name: "Cards", bundle: nil)
        let nextViewController = storyBoard.instantiateViewController(withIdentifier: "CardsTableViewController")
        if let nextViewController = nextViewController as? CardsTableViewController {
            nextViewController.cardList = cardList
            nextViewController.delegate = self
            nextViewController.signDelegate = self
            nextViewController.tableView.reloadData()
        }
        
        
    }
    
    //MARK: delegate
    
    func didRemoveCards(){
        cardList.removeAll()
    }
    
    func didCheck(cardRow:Int, checkResult:Bool){
    cardList[cardRow].checked = true
    cardList[cardRow].checkedResult = checkResult
    
    }
    
    func didBalance(cardRow:Int,_ card:Card){
        cardList[cardRow] = card
        
    }
    
   

}

extension ReaderViewController: CardParserDelegate {
    
    func cardParserWrongTLV(_ parser: CardParser) {
        let validationAlert = UIAlertController(title: "Failed to parse data received from the banknote", message: "", preferredStyle: .alert)
        validationAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(validationAlert, animated: true, completion: nil)
    }
    
    func cardParserLockedCard(_ parser: CardParser) {
        print("Card is locked, two first bytes are equel 0x6A86")
        let validationAlert = UIAlertController(title: "This app can’t read protected Tangem banknotes", message: "", preferredStyle: .alert)
        validationAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(validationAlert, animated: true, completion: nil)
    }
    
    func cardParser(_ parser: CardParser, didFinishWith card: Card) {
        switch card.type {
        case .btc:
            self.addCardWallet(card)
        case .eth:
            self.addCardWallet(card)
        default:
            self.addCardNoWallet(card)
        }
    }
}

