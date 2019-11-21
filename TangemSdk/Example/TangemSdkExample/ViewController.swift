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
                if let error = error {
                    if case .userCancelled = error {
                        //silence user cancelled
                    } else {
                        self.log("completed with error: \(error.localizedDescription)")
                    }
                }
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
                    if let error = error {
                        if case .userCancelled = error {
                            //silence user cancelled
                        } else {
                            self.log("completed with error: \(error.localizedDescription)")
                        }
                    }
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
            let getIssuerDataCommand = ReadIssuerDataCommand(cardId: cardId)
            
            cardManager.runCommand(getIssuerDataCommand) { [unowned self] taskEvent in
                switch taskEvent {
                case .event(let issuerDataResponse):
                    self.issuerDataResponse = issuerDataResponse
                    self.log(issuerDataResponse)
                case .completion(let error):
                    if let error = error {
                        if case .userCancelled = error {
                            //silence user cancelled
                        } else {
                            self.log("completed with error: \(error.localizedDescription)")
                        }
                    }
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
            let writeIssuerDataCommand = WriteIssuerDataCommand(cardId: cardId, issuerData: issuerDataResponse.issuerData, issuerDataSignature: issuerDataResponse.issuerDataSignature)
            
            cardManager.runCommand(writeIssuerDataCommand) { [unowned self] taskEvent in
                switch taskEvent {
                case .event(let issuerDataResponse):
                    self.log(issuerDataResponse)
                case .completion(let error):
                    if let error = error {
                        if case .userCancelled = error {
                            //silence user cancelled
                        } else {
                            self.log("completed with error: \(error.localizedDescription)")
                        }
                    }
                    //handle completion. Unlock UI, etc.
                }
            }
        } else {
            // Fallback on earlier versions
            self.log("Only iOS 13+")
        }
    }
    
    private func log(_ object: Any) {
        self.logView.text = self.logView.text.appending("\(object)\n")
        print(object)
    }
}
