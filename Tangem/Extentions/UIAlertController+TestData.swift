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
        let updatedSpec = UIAlertAction(title: "BTC Upd", style: .default) { (_) in
            handler(TestData.xrpEdDSA)
        }
        let btcAction = UIAlertAction(title: "BTC", style: .default) { (_) in
            handler(TestData.btcWallet)
        }
        let btcNoWalletAction = UIAlertAction(title: "BTC No Wallet", style: .default) { (_) in
            handler(TestData.btcNoWallet)
        }
        let seedAction = UIAlertAction(title: "SEED", style: .default) { (_) in
            handler(TestData.seed)
        }
        let ethAction = UIAlertAction(title: "ETH", style: .default) { (_) in
            handler(TestData.ethWallet)
        }
        let ethLoadedAction = UIAlertAction(title: "ETH Loaded", style: .default) { (_) in
            handler(TestData.ethLoaded)
        }
        let qlearAction = UIAlertAction(title: "Qlear", style: .default) { (_) in
            handler(TestData.qlear)
        }
        let whirlAction = UIAlertAction(title: "Whirl", style: .default) { (_) in
            handler(TestData.whirl)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        alertController.addAction(updatedSpec)
        alertController.addAction(btcAction)
        alertController.addAction(btcNoWalletAction)
        alertController.addAction(ethAction)
        alertController.addAction(ethLoadedAction)
        alertController.addAction(seedAction)
        alertController.addAction(qlearAction)
        alertController.addAction(whirlAction)
        alertController.addAction(cancelAction)
        
        return alertController
    }
    
}
