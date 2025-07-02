//
//  WCEthTransactionDetailsModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

/// Model for ETH transaction details (eth_signTransaction and eth_sendTransaction)
struct WCEthTransactionDetailsModel {
    let data: [WCTransactionDetailsSection]

    init(for method: WalletConnectMethod, source: Data) {
        guard let transaction = try? JSONDecoder().decode(WalletConnectEthTransaction.self, from: source) else {
            data = []
            return
        }

        data = WCRequestDetailsEthTransactionParser.parse(transaction: transaction, method: method)
    }
}
