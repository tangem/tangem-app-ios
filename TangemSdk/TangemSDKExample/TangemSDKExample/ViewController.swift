//
//  ViewController.swift
//  TangemSDKExample
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import UIKit
import TangemSdk
import CoreNFC

class ViewController: UIViewController {
    
    var cardManager: CardManager = CardManager()
    
    @IBAction func scanCardTapped(_ sender: Any) {
        cardManager.scanCard {[unowned self] scanResult, cardEnvironment in
            switch scanResult {
            case .failure(let error):
                print("error: \(error.localizedDescription)")
                let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.show(alertController, sender: nil)
            case .onRead(let card):
                print("read result: \(card)")
            case .onVerify(let isGenuine):
                print("verify result: \(isGenuine)")
            case .userCancelled:
                print("user cancelled")
            }
        }
    }
    
    @IBAction func signHashesTapped(_ sender: Any) {
        let hash1 = Data(repeating: 1, count: 32)
        let hash2 = Data(repeating: 2, count: 32)
        let hashes = [hash1, hash2]
        let cardId = "CB05000000017715"
        cardManager.sign(hashes: hashes, environment: CardEnvironment(cardId: cardId)) { result, cardEnvironment in
            switch result {
            case .success(let signResponse):
                print(signResponse)
            case .failure(let error):
                print(error.localizedDescription)
            case .userCancelled:
                  print("user cancelled")
            }
        }
    }
}
