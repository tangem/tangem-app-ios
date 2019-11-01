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
    
    var cardManager: CardManager = CardManager()
    
    var card: Card?
    
    @IBAction func scanCardTapped(_ sender: Any) {
        cardManager.scanCard {[unowned self] taskEvent in
            switch taskEvent {
            case .event(let scanEvent):
                switch scanEvent {
                case .onRead(let card):
                    self.card = card
                    print("read result: \(card)")
                case .onVerify(let isGenuine):
                    print("verify result: \(isGenuine)")
                }
            case .completion(let error):
                if let error = error {
                    if case .userCancelled = error {
                        //silence user cancelled
                    } else {
                        print("completed with error: \(error.localizedDescription)")
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
                print("Please, scan card before")
                return
            }
            
            cardManager.sign(hashes: hashes, cardId: cardId) { taskEvent  in
                switch taskEvent {
                case .event(let signResponse):
                    print(signResponse)
                case .completion(let error):
                    if let error = error {
                        if case .userCancelled = error {
                            //silence user cancelled
                        } else {
                            print("completed with error: \(error.localizedDescription)")
                        }
                    }
                    //handle completion. Unlock UI, etc.
                }
            }
        } else {
            // Fallback on earlier versions
            print("Only iOS 13+")
        }
    }
}
