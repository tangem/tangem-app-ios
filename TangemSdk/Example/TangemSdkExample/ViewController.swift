//
//  ViewController.swift
//  TangemSDKExample
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import UIKit
import TangemSdk

class ViewController: UIViewController {
    @IBOutlet weak var logView: UITextView!
    
    var cardManager: CardManager = CardManager()
    
    var card: Card?
    var issuerDataResponse: ReadIssuerDataResponse?
    var issuerExtraDataResponse: ReadIssuerExtraDataResponse?
    
    @IBAction func scanCardTapped(_ sender: Any) {
        cardManager.scanCard {[unowned self] taskEvent in
            switch taskEvent {
            case .event(let scanEvent):
                switch scanEvent {
                case .onRead(let card):
                    self.card = card
                    self.logView.text = ""
                    self.log("read result: \(card)")
                case .onVerify(let isGenuine):
                    self.log("verify result: \(isGenuine)")
                }
            case .completion(let error):
                self.handle(error)
                //handle completion. Unlock UI, etc.
            }
        }
    }
    
    @IBAction func signHashesTapped(_ sender: Any) {
        if #available(iOS 13.0, *) {
            let hash1 = Data(repeating: 1, count: 32) //dummy hashes
            let hash2 = Data(repeating: 2, count: 32)
            let hashes = [hash1, hash2]
            guard let cardId = card?.cardId else {
                self.log("Please, scan card before")
                return
            }
            
            cardManager.sign(hashes: hashes, cardId: cardId) {[unowned self] taskEvent  in
                switch taskEvent {
                case .event(let signResponse):
                    self.log(signResponse)
                case .completion(let error):
                    self.handle(error)
                    //handle completion. Unlock UI, etc.
                }
            }
        } else {
            // Fallback on earlier versions
            self.log("Only iOS 13+")
        }
    }
    @IBAction func getIssuerDataTapped(_ sender: Any) {
        guard let cardId = card?.cardId else {
            self.log("Please, scan card before")
            return
        }
        
        if #available(iOS 13.0, *) {
            cardManager.readIssuerData(cardId: cardId){ [unowned self] taskEvent in
                switch taskEvent {
                case .event(let issuerDataResponse):
                    self.issuerDataResponse = issuerDataResponse
                    self.log(issuerDataResponse)
                case .completion(let error):
                    self.handle(error)
                    //handle completion. Unlock UI, etc.
                }
            }
        } else {
            // Fallback on earlier versions
            self.log("Only iOS 13+")
        }
    }
    
    @IBAction func writeIssuerDataTapped(_ sender: Any) {
        guard let cardId = card?.cardId else {
            self.log("Please, scan card before")
            return
        }
        
        guard let issuerDataResponse = issuerDataResponse else {
            self.log("Please, run GetIssuerData before")
            return
        }
        
        if #available(iOS 13.0, *) {
            cardManager.writeIssuerData(cardId: cardId,
                                        issuerData: issuerDataResponse.issuerData,
                                        issuerDataSignature: issuerDataResponse.issuerDataSignature) { [unowned self] taskEvent in
                                            switch taskEvent {
                                            case .event(let issuerDataResponse):
                                                self.log(issuerDataResponse)
                                            case .completion(let error):
                                                self.handle(error)
                                                //handle completion. Unlock UI, etc.
                                            }
            }
        } else {
            // Fallback on earlier versions
            self.log("Only iOS 13+")
        }
    }
    @IBAction func readIssuerExtraDatatapped(_ sender: Any) {
        guard let cardId = card?.cardId else {
            self.log("Please, scan card before")
            return
        }
        
        if #available(iOS 13.0, *) {
            cardManager.readIssuerExtraData(cardId: cardId){ [unowned self] taskEvent in
                switch taskEvent {
                case .event(let issuerDataResponse):
                    self.issuerExtraDataResponse = issuerDataResponse
                    self.log(issuerDataResponse)
                    print(issuerDataResponse.issuerData.asHexString())
                case .completion(let error):
                    self.handle(error)
                    //handle completion. Unlock UI, etc.
                }
            }
        } else {
            // Fallback on earlier versions
            self.log("Only iOS 13+")
        }
    }
    
    @IBAction func writeIssuerExtraDataTapped(_ sender: Any) {
        guard let cardId = card?.cardId else {
            self.log("Please, scan card before")
            return
        }
        
        guard let issuerDataResponse = issuerExtraDataResponse else {
            self.log("Please, run GetIssuerExtraData before")
            return
        }
        let newCounter = (issuerDataResponse.issuerDataCounter ?? 0) + 1
        let sampleData = Data(repeating: UInt8(1), count: 2000)
        let issuerKey = Data(hexString: "11121314151617184771ED81F2BACF57479E4735EB1405083927372D40DA9E92")
        
        let startSig = CryptoUtils.signSecp256k1(Data(hexString: cardId) + newCounter.bytes4 + sampleData.count.bytes2, with: issuerKey)!
        let finalSig = CryptoUtils.signSecp256k1(Data(hexString: cardId) + sampleData + newCounter.bytes4, with: issuerKey)!
        
        if #available(iOS 13.0, *) {
            cardManager.writeIssuerExtraData(cardId: cardId,
                                             issuerData: sampleData,
                                             startingSignature: startSig,
                                             finalizingSignature: finalSig,
                                             issuerDataCounter: newCounter) { [unowned self] taskEvent in
                                                switch taskEvent {
                                                case .event(let writeResponse):
                                                    self.log(writeResponse)
                                                case .completion(let error):
                                                    self.handle(error)
                                                    //handle completion. Unlock UI, etc.
                                                }
            }
        } else {
            // Fallback on earlier versions
            self.log("Only iOS 13+")
        }
    }
    
    @IBAction func createWalletTapped(_ sender: Any) {
        guard let cardId = card?.cardId else {
            self.log("Please, scan card before")
            return
        }
        
        if #available(iOS 13.0, *) {
            cardManager.createWallet(cardId: cardId) { [unowned self] taskEvent in
                switch taskEvent {
                case .event(let createWalletEvent):
                    switch createWalletEvent {
                    case .onCreate(let response):
                        self.log(response)
                    case .onVerify(let isGenuine):
                        self.log("Verify result: \(isGenuine)")
                    }
                    
                case .completion(let error):
                    self.handle(error)
                    //handle completion. Unlock UI, etc.
                }
            }
        } else {
            // Fallback on earlier versions
            self.log("Only iOS 13+")
        }
        
    }
    
    @IBAction func purgeWalletTapped(_ sender: Any) {
        guard let cardId = card?.cardId else {
            self.log("Please, scan card before")
            return
        }
        
        if #available(iOS 13.0, *) {
            cardManager.purgeWallet(cardId: cardId) { [unowned self] taskEvent in
                switch taskEvent {
                case .event(let response):
                    self.log(response)
                case .completion(let error):
                    self.handle(error)
                    //handle completion. Unlock UI, etc.
                }
            }
        } else {
            // Fallback on earlier versions
            self.log("Only iOS 13+")
        }
    }
    @IBAction func clearTapped(_ sender: Any) {
        self.logView.text = ""
    }
    
    private func log(_ object: Any) {
        self.logView.text = self.logView.text.appending("\(object)\n\n")
        print(object)
    }
    
    private func handle(_ error: TaskError?) {
        if let error = error, !error.isUserCancelled {
            self.log("completed with error: \(error.localizedDescription)")
        }
    }
}
