//
//  UIAlertController+TestData.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import Foundation

extension UIAlertController {
    
    static func testDataAlertController(handler: @escaping (TestData) -> Void) -> UIAlertController {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let btcAction = UIAlertAction(title: "BTC", style: .default) { (_) in
            handler(TestData.btcWallet)
        }
        let seedAction = UIAlertAction(title: "SEED", style: .default) { (_) in
            handler(TestData.seed)
        }
        let ethAction = UIAlertAction(title: "ETH", style: .default) { (_) in
            handler(TestData.ethWallet)
        }
        let ertAction = UIAlertAction(title: "ERT", style: .default) { (_) in
            handler(TestData.ert)
        }
        let qlearAction = UIAlertAction(title: "Qlear", style: .default) { (_) in
            handler(TestData.qlear)
        }
        let noWalletAction = UIAlertAction(title: "No wallet", style: .default) { (_) in
            handler(TestData.noWallet)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(btcAction)
        alertController.addAction(ethAction)
        alertController.addAction(ertAction)
        alertController.addAction(seedAction)
        alertController.addAction(qlearAction)
        alertController.addAction(noWalletAction)
        alertController.addAction(cancelAction)
        
        return alertController
    }
    
}
