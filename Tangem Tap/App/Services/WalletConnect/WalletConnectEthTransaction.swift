//
//  WalletConnectEthTransaction.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

struct WalletConnectEthTransaction: Codable {
    let from: String // Required
    let to: String // Required
    let gasPrice: String // Required
    let value: String // Required
    let data: String // Required
    let gas: String?
    let gasLimit: String?
    let nonce: String?
    
    var description: String {
        return """
        to: \(to),
        value: \(value),
        gasPrice: \(gasPrice),
        gas: \(gas ?? gasLimit ?? "not specified"),
        data: \(data.count > 30 ? "\(data.prefix(10))...\(data.suffix(10))" : data),
        nonce: \(nonce ?? "not specified")
        """
    }
}
