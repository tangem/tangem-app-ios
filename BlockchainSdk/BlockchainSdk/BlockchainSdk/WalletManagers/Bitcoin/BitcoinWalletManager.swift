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
    private let txBuilder: BitcoinTransactionBuilder
    
    init(walletPublicKey: Data, walletConfig: WalletConfig, isTestnet: Bool) {
        self.blockchain = isTestnet ? .bitcoinTestnet : .bitcoin
        let address = blockchain.makeAddress(from: walletPublicKey)
        self._wallet = CurrencyWallet(config: walletConfig, address: address)
        self.walletPublicKey = walletPublicKey
        self.txBuilder = BitcoinTransactionBuilder(walletAddress: address, isTestnet: isTestnet)
    }
    
    func update() {
        //[REDACTED_TODO_COMMENT]
    }
}

extension BitcoinWalletManager: TransactionBuilder {
    func getEstimateSize(for transaction: Transaction) -> Int {
        return 0
    }
}

extension BitcoinWalletManager: TransactionSender {
    func send(_ transaction: Transaction, signer: TransactionSigner) {
        
    }
}

extension BitcoinWalletManager: FeeProvider {
    func getFee(amount: Amount, source: String, destination: String) -> [Amount]? {
        return nil
    }
}
