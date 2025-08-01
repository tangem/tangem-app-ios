//
//  WCEthTransactionDetailsModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct WCEthTransactionDetailsModel {
    let data: [WCTransactionDetailsSection]

    private let blockchain: Blockchain

    init(for method: WalletConnectMethod, source: Data, blockchain: Blockchain) {
        self.blockchain = blockchain

        guard let transaction = try? JSONDecoder().decode(WalletConnectEthTransaction.self, from: source) else {
            data = []
            return
        }

        data = WCRequestDetailsEthTransactionParser.parse(
            transaction: transaction,
            method: method,
            blockchain: blockchain
        )
    }
}
