//
//  WalletConnectEthTransaction.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

struct WalletConnectEthTransaction: Codable {
    let from: String // Required
    let to: String // Required
    let value: String? // Required
    let data: String // Required
    let gas: String?
    let gasPrice: String?
    let nonce: String?

    var description: String {
        return """
        to: \(to),
        value: \(value ?? "0"),
        gasPrice: \(gasPrice ?? "not specified"),
        data: \(data.count > 30 ? "\(data.prefix(10))...\(data.suffix(10))" : data),
        nonce: \(nonce ?? "not specified")
        """
    }
}

extension WalletConnectEthTransaction {
    init(from transaction: WalletConnectEthTransaction, gas: String? = nil, gasPrice: String? = nil) {
        from = transaction.from
        to = transaction.to
        value = transaction.value
        data = transaction.data
        self.gas = gas ?? transaction.gas
        self.gasPrice = gasPrice ?? transaction.gasPrice
        nonce = transaction.nonce
    }
}
