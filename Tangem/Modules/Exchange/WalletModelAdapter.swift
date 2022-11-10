//
//  WalletModelAdapter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

class WalletModelAdapter: ExchangeManager {
    let walletManager: WalletManager

    var walletAddress: String {
        walletManager.wallet.address
    }

    init(walletManager: WalletManager) {
        self.walletManager = walletManager
    }

    func send(_ tx: Transaction, signer: TangemSigner) async throws {
        try await walletManager.send(tx, signer: signer).async()
    }

    func getFee(amount: Amount, destination: String) async throws -> [Amount] {
        try await walletManager
            .getFee(amount: amount, destination: destination)
            .async()
    }

    func createTransaction(amount: Amount,
                           fee: Amount,
                           destinationAddress: String,
                           sourceAddress: String? = nil,
                           changeAddress: String? = nil) throws -> Transaction {
        try walletManager.createTransaction(amount: amount,
                                            fee: fee,
                                            destinationAddress: destinationAddress,
                                            sourceAddress: sourceAddress,
                                            changeAddress: changeAddress)
    }
}
