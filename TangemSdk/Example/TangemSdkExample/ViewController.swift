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
    
    var tangemSdk = TangemSdk()
    var card: Card?
    var issuerDataResponse: ReadIssuerDataResponse?
    var issuerExtraDataResponse: ReadIssuerExtraDataResponse?
    
    @IBAction func scanCardTapped(_ sender: Any) {
        if #available(iOS 13.0, *) {
            tangemSdk.start(cardId: nil) { session, error in
                let cmd1 = CheckWalletCommand(curve: session.environment.card!.curve!, publicKey: session.environment.card!.walletPublicKey!)
                cmd1!.run(in: session, completion: { result in
                    switch result {
                    case .success(let response):
                         let cmd2 = CheckWalletCommand(curve: session.environment.card!.curve!, publicKey: session.environment.card!.walletPublicKey!)
                        cmd2!.run(in: session, completion: { result in
                                           switch result {
                                           case .success(let response):
                                              print("ZZZZZZZZZ")
                                           case .failure(let error):
                                               print("!!!")
                                           }
                                       })
                    case .failure(let error):
                        print("!!!")
                    }
                })
            }
        } else {
            // Fallback on earlier versions
        }
        
        
        tangemSdk.scanCard {[unowned self] result in
            switch result {
            case .success(let card):
                self.card = card
                self.logView.text = ""
                self.log("read result: \(card)")
            case .failure(let error):
                self.handle(error)
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
            
            tangemSdk.sign(hashes: hashes, cardId: cardId) {[unowned self] result in
                switch result {
                case .success(let signResponse):
                    self.log(signResponse)
                case .failure(let error):
                    self.handle(error)
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
            tangemSdk.readIssuerData(cardId: cardId){ [unowned self] result in
                switch result {
                case .success(let issuerDataResponse):
                    self.issuerDataResponse = issuerDataResponse
                    self.log(issuerDataResponse)
                case .failure(let error):
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
            tangemSdk.writeIssuerData(cardId: cardId,
                                        issuerData: issuerDataResponse.issuerData,
                                        issuerDataSignature: issuerDataResponse.issuerDataSignature) { [unowned self] result in
                                            switch result {
                                            case .success(let issuerDataResponse):
                                                self.log(issuerDataResponse)
                                            case .failure(let error):
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
            tangemSdk.readIssuerExtraData(cardId: cardId){ [unowned self] result in
                switch result {
                case .success(let issuerDataResponse):
                    self.issuerExtraDataResponse = issuerDataResponse
                    self.log(issuerDataResponse)
                    print(issuerDataResponse.issuerData.asHexString())
                case .failure(let error):
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
            tangemSdk.writeIssuerExtraData(cardId: cardId,
                                             issuerData: sampleData,
                                             startingSignature: startSig,
                                             finalizingSignature: finalSig,
                                             issuerDataCounter: newCounter) { [unowned self] result in
                                                switch result {
                                                case .success(let writeResponse):
                                                    self.log(writeResponse)
                                                case .failure(let error):
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
            tangemSdk.createWallet(cardId: cardId) { [unowned self] result in
                switch result {
                case .success(let response):
                    self.log(response)
                case .failure(let error):
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
            tangemSdk.purgeWallet(cardId: cardId) { [unowned self] result in
                switch result {
                case .success(let response):
                    self.log(response)
                case .failure(let error):
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
    
    private func handle(_ error: SessionError?) {
        if let error = error, !error.isUserCancelled {
            self.log("completed with error: \(error.localizedDescription)")
        }
    }
}
