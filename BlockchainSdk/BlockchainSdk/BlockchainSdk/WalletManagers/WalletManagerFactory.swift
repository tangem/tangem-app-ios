//
//  BlockchainFactory.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public class WalletManagerFactory {
    public func makeWalletManager(from card: Card) -> WalletManager? {
        guard let blockchainName = card.cardData?.blockchainName, let walletPublicKey = card.walletPublicKey else {
            assertionFailure()
            return nil
        }
        
        let blockchain = Blockchain.from(name: blockchainName)
        
        switch blockchain {
        case .bitcoin:
            return BitcoinWalletManager(walletPublicKey: walletPublicKey, blockchain: blockchain)
        default:
            fatalError("unsupported")
        }
    }
}
