//
//  EthereumResponse.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - Params

struct GasLimitParams: Encodable {
    let to: String
    let from: String
    let value: String?
    let data: String?
}

struct CallParams: Encodable {
    let to: String
    let data: String
}

// MARK: - Response

struct EthereumFeeHistoryResponse: Decodable {
    let baseFeePerGas: [String]
    let reward: [[String]]
}
