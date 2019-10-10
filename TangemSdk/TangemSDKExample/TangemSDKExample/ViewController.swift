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
    
    @IBAction func scanCardTapped(_ sender: Any) {
        cardManager.scanCard {[unowned self] scanResult in
            switch scanResult {
            case .failure(let error):
                print("error: \(error)")
                let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.show(alertController, sender: nil)
            case .onRead(let card):
                print("read result: \(card)")
            case .onVerify(let isGenuine):
                print("verify result: \(isGenuine)")
            }
        }
    }
}
