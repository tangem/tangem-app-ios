//
//  EthTransaction.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

struct EthTransaction: Codable {
    let from: String // Required
    let to: String // Required
    let gas: String // Required
    let gasPrice: String // Required
    let value: String // Required
    let data: String // Required
    let nonce: String // Required
    
    var description: String {
        return """
        to: \(to),
        value: \(value),
        gasPrice: \(gasPrice),
        gas: \(gas),
        data: \(data),
        nonce: \(nonce)
        """
    }
}
