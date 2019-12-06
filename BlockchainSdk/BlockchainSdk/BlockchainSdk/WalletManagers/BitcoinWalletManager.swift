//
//  Bitcoin.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class BitcoinWalletManager: WalletManager {
    var wallet: Wallet { return _wallet }
    let blockchain: Blockchain
    
    private let _wallet: CurrencyWallet
    private let walletPublicKey: Data
    
    init(walletPublicKey: Data, blockchain: Blockchain) {
        let address = blockchain.makeAddress(from: walletPublicKey)
        let walletConfig = WalletConfig(allowFeeSelection: true, allowFeeInclusion: true)
        self._wallet = CurrencyWallet(config: walletConfig, address: address)
        self.blockchain = blockchain
        self.walletPublicKey = walletPublicKey
    }
  
    func update() {
        
    }
}
