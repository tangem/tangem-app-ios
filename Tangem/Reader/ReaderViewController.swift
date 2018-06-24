//
//  ViewController.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Yulia Moskaleva. All rights reserved.
//

import UIKit


protocol RemoveCardsDelegate: class{ func didRemoveCards() }
class ReaderViewController: UIViewController,RemoveCardsDelegate,DidSignCheckDelegate {
    var cardList = [Card]()
    let helper = NFCHelper()
    
    override func viewWillAppear(_ animated: Bool) {
         self.navigationController?.navigationBar.barTintColor = UIColor(red:0.0074375583790242672, green: 0.24186742305755615, blue: 0.4968341588973999, alpha: 1)
        helper.onNFCResult = onNFCResult(success:msg:)
        helper.restartSession()
        
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    //MARK: Private methods
    //Mark: Actions
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
        //cardParsing(TestData.btcWallet.rawValue)
        
        
        
        
    }
    
    func onNFCResult(success: Bool, msg: String) {
        DispatchQueue.main.async {
            if(success){
                self.cardParsing(msg)
            } else {
                print("\(msg)")
            }
        }
    }
    //MARK: Card Parsing
    func cardParsing(_ payload: String){
        //Check if Hex String is corect
        guard let payloadArr = payload.asciiHexToData()else {
            print("Error of payload")
            return
        }
        let payloadSize = payloadArr.count
        var offset:Int = 0
        //Check if Card is locked
        guard let _ = TLV.checkPIN(payloadArr,&offset) else {
            print("Card is locked, two first bytes are equel 0x6A86")
            let validationAlert = UIAlertController(title: "This app can’t read protected Tangem banknotes", message: "", preferredStyle: .alert)
            validationAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(validationAlert, animated: true, completion: nil)
            return
        }
        var tmpCard = Card()
        
        var cardArr = [UInt8]()
        var cardArrSize = 0
        var cardOffset:Int = 0
        while (offset < payloadSize){
            do {
                let tmp = try TLV(data: payloadArr,&offset)
                print("TLV after Name: \(tmp.name)")
                print("TLV after Tag: \(tmp.tagTLV)")
                print("TLV after LengthTLV: \(tmp.lengthTLV)")
                print("TLV after TagTLVHex: \(tmp.tagTLVHex)")
                print("TLV after ValueTLV: \(tmp.valueTLV)")
                print("Ready For Display: \(tmp.readyValue)")
                print("Ready Hex: \(tmp.valueHex)")
                if tmp.name == "Card_Data" {
                    cardArr = tmp.valueTLV
                }
                if tmp.name == "CardID" {
                    tmpCard.CardID = tmp.readyValue
                }
                if tmp.name == "RemainingSignatures" {
                    tmpCard.RemainingSignatures = tmp.readyValue
                }
                if tmp.name == "Wallet_PublicKey" {
                    tmpCard.isWallet = true
                    tmpCard.hexPublicKey = tmp.valueHex
                    tmpCard.pubArr = tmp.valueTLV
                }
                if tmp.name == "Wallet_Signature"{
                    tmpCard.signArr = tmp.valueTLV
                }
                if tmp.name == "Salt" {
                    tmpCard.Salt = tmp.valueHex.lowercased()
                }
                if tmp.name == "Challenge" {
                    tmpCard.Challenge = tmp.valueHex.lowercased()
                }
                if tmp.name == "SignedHashes" {
                    tmpCard.SignedHashes = tmp.valueHex
                }
                
            } catch TLVError.wrongTLV {
                let validationAlert = UIAlertController(title: "Failed to parse data received from the banknote", message: "", preferredStyle: .alert)
                validationAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(validationAlert, animated: true, completion: nil)
            } catch {
                
            }
            
        }
        if tmpCard.isWallet {
            cardArrSize = cardArr.count
            while (cardOffset < cardArrSize){
                do {
                    let tmp = try TLV(data: cardArr,&cardOffset)
                    print("TLV after Name: \(tmp.name)")
                    print("TLV after Tag: \(tmp.tagTLV)")
                    print("TLV after LengthTLV: \(tmp.lengthTLV)")
                    print("TLV after TagTLVHex: \(tmp.tagTLVHex)")
                    print("TLV after ValueTLV: \(tmp.valueTLV)")
                    print("Ready For Display: \(tmp.readyValue)")
                    
                    if tmp.name == "Blockchain_Name" {
                        tmpCard.BlockchainName = tmp.readyValue
                    }
                    if tmp.name == "Issuer_Name" {
                        tmpCard.Issuer = tmp.readyValue
                    }
                    if tmp.name == "Firmware" {
                        tmpCard.Firmware = tmp.readyValue
                    }
                    if tmp.name == "Manufacture_Date_Time" {
                        tmpCard.Manufacture_Date_Time = tmp.readyValue
                    }
                    if tmp.name == "SignedHashes" {
                        tmpCard.SignedHashes = tmp.valueHex
                    }
                    
                } catch TLVError.wrongTLV {
                    let validationAlert = UIAlertController(title: "Failed to parse data received from the banknote", message: "", preferredStyle: .alert)
                    validationAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(validationAlert, animated: true, completion: nil)
                } catch {
                    
                }
                
            }
            //Ribbon Check
            tmpCard.ribbonCase = checkRibbonCase(tmpCard)
            
            let Blockchain = tmpCard.BlockchainName
            
            if Blockchain.containsIgnoringCase(find: "bitcoin") || Blockchain.containsIgnoringCase(find: "btc") {
                //We think that card is BTC
                tmpCard.type = "btc"
                tmpCard.test = "0"
                tmpCard.Blockchain = "Bitcoin"
                tmpCard.Node = randomNode()
                if Blockchain.containsIgnoringCase(find: "test"){
                    tmpCard.test = "1"
                    tmpCard.Blockchain = "Bitcoin TestNet"
                    tmpCard.Node = randomTestNode()
                }
                if let addr = getAddress(tmpCard.hexPublicKey) {
                    tmpCard.BtcAddressMain = addr[0]
                    tmpCard.BtcAddressTest = addr[1]
                }
                tmpCard.WalletUnits = "mBTC"
                if tmpCard.test == "0" {
                    tmpCard.Address = tmpCard.BtcAddressMain
                    tmpCard.Link = Links.bitcoinMainLink + tmpCard.Address
                } else {
                   tmpCard.Address = tmpCard.BtcAddressTest
                   tmpCard.Link = Links.bitcoinTestLink + tmpCard.Address
                }
                tmpCard.checkedBalance = false
                addCardWallet(tmpCard)
                //addBTCBalance(tmpCard)
            }
            if Blockchain.containsIgnoringCase(find: "eth") {
                //We think that card is ETC
                tmpCard.type = "eth"
                tmpCard.test = "0"
                tmpCard.Blockchain = "Ethereum"
                tmpCard.Node = "mainnet.infura.io"
                if Blockchain.containsIgnoringCase(find: "test"){
                    tmpCard.test = "1"
                    tmpCard.Blockchain = "Ethereum Rinkeby"
                    tmpCard.Node = "rinkeby.infura.io"
                }
                tmpCard.EthAddress = getEthAddress(tmpCard.hexPublicKey)
                tmpCard.WalletUnits = "ETH"
                tmpCard.Address = tmpCard.EthAddress
                if tmpCard.test == "0" {
                    tmpCard.Link = Links.ethereumMainLink + tmpCard.Address
                } else {
                    tmpCard.Link = Links.ethereumTestLink + tmpCard.Address
                }
                
                tmpCard.checkedBalance = false
                addCardWallet(tmpCard)
                //addETHBalance(tmpCard)
            }
            
            
        } else {
            //Ribbon Check
            tmpCard.ribbonCase = checkRibbonCase(tmpCard)
            
            addCardNoWallet(tmpCard)
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
        
        if card.test == "1" {
            
            balanceGroup.enter()
            BalanceService.sharedInstance.getBitcoinTestNet(card.BtcAddressTest) { success, error in
                if let success = success {
                    tmpCard.value = success
                }
                if let _ = error {
                    tmpCard.WalletValue = ""
                    tmpCard.USDWalletValue = ""
                    tmpCard.error = 1
                }
                balanceGroup.leave()
            }
        } else {
            
            balanceGroup.enter()
            BalanceService.sharedInstance.getBitcoinMain(card.BtcAddressMain) { success, error in
                if let success = success {
                    tmpCard.value = success
                }
                if let _ = error {
                    tmpCard.WalletValue = ""
                    tmpCard.USDWalletValue = ""
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
            tmpCard.WalletValue = String(format: "%.2f", round(first*100)/100)
            let second = price_usd/1000.0
            let value = first*second
            tmpCard.USDWalletValue = String(format: "%.2f", round(value*100)/100)
            if(tmpCard.mult == "0"){
                 tmpCard.USDWalletValue = ""
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
        tmpCard.WalletUnits = "ETH"
        tmpCard.Address = card.EthAddress
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
        
        if card.test == "1" {
            balanceGroup.enter()
            BalanceService.sharedInstance.getEthereumTestNet(card.EthAddress) { success, error in
                    if let success = success {
                        tmpCard.valueUInt64 = success
                    }
                    if let _ = error {
                        tmpCard.WalletValue = ""
                        tmpCard.USDWalletValue = ""
                        tmpCard.error = 1
                    }
                balanceGroup.leave()
            }
        } else {
            balanceGroup.enter()
            BalanceService.sharedInstance.getEthereumMainNet(card.EthAddress) { success, error in
                if let success = success {
                    tmpCard.valueUInt64 = success
                }
                if let _ = error {
                    tmpCard.WalletValue = ""
                    tmpCard.USDWalletValue = ""
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
            tmpCard.WalletValue = String(format: "%.2f", round(first*100)/100)
            let second = price_usd
            let value = first*second
            tmpCard.USDWalletValue = String(format: "%.2f", round(value*100)/100)
            if(tmpCard.mult == "0"){
                tmpCard.USDWalletValue = ""
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
    func addCardWithWallet(_ card:Card){
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
    func addCardNoWallet(_ card:Card){
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
    func addCardWallet(_ card:Card){
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
            if elem.CardID == card.CardID {
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
                            
                            //Время возвращаться в главную ветку
                            DispatchQueue.main.async {
                                //Вернулись в главную нитку
                                print("\(tmpCard.mult)")
                                print("\(tmpCard.WalletValue)")
                                print("\(tmpCard.USDWalletValue)")
                                print("\(tmpCard.error)")
                                self.didReturnInMainThread(tmpCard)
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
                            //Время возвращаться в главную ветку
                            DispatchQueue.main.async {
                                //Вернулись в главную нитку
                                print("\(tmpCard.mult)")
                                print("\(tmpCard.WalletValue)")
                                print("\(tmpCard.USDWalletValue)")
                                print("\(tmpCard.error)")
                                self.didReturnInMainThread(tmpCard)
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
                            //Время возвращаться в главную ветку
                            DispatchQueue.main.async {
                                //Вернулись в главную нитку
                                print("\(tmpCard.mult)")
                                print("\(tmpCard.WalletValue)")
                                print("\(tmpCard.USDWalletValue)")
                                print("\(tmpCard.error)")
                                self.didReturnInMainThread(tmpCard)
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
                            print("Card BTC \(tmpCard)")//Place for calculation
                            //Время возвращаться в главную ветку
                            DispatchQueue.main.async {
                                //Вернулись в главную нитку
                                print("\(tmpCard.mult)")
                                print("\(tmpCard.WalletValue)")
                                print("\(tmpCard.USDWalletValue)")
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
            if elem.CardID == card.CardID {
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

