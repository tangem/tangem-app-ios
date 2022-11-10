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
    let walletModel: WalletModel

    var walletAddress: String {
        walletModel.wallet.address
    }

    init(walletModel: WalletModel) {
        self.walletModel = walletModel
    }

    func send(_ tx: Transaction, signer: TangemSigner) async throws {
        try await walletModel
            .send(tx, signer: signer)
            .async()
    }

    func getFee(amount: Amount, destination: String) async throws -> [Amount] {
        try await walletModel.walletManager
            .getFee(amount: amount, destination: destination)
            .async()
    }

    func createTransaction(amount: Amount,
                           fee: Amount,
                           destinationAddress: String,
                           sourceAddress: String? = nil,
                           changeAddress: String? = nil) throws -> Transaction {
        try walletModel.walletManager.createTransaction(amount: amount,
                                                        fee: fee,
                                                        destinationAddress: destinationAddress,
                                                        sourceAddress: sourceAddress,
                                                        changeAddress: changeAddress)
    }
}
