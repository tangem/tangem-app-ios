//
//  EthereumModels.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

/// Final Ethereum response that contain all information about address
struct EthereumInfoResponse {
    let balance: Decimal
    let tokenBalances: [Token: Result<Decimal, Error>]
}

struct EthereumEIP1559FeeResponse {
    let gasLimit: BigUInt
    let fees: (low: ETHFee, market: ETHFee, fast: ETHFee)

    struct ETHFee {
        let max: BigUInt
        let priority: BigUInt
    }
}

struct EthereumLegacyFeeResponse {
    let gasLimit: BigUInt
    let lowGasPrice: BigUInt
    let marketGasPrice: BigUInt
    let fastGasPrice: BigUInt
}

public struct EthereumFeeHistory {
    /// for pending block
    public let baseFee: BigUInt

    public let lowBaseFee: BigUInt
    public let marketBaseFee: BigUInt
    public let fastBaseFee: BigUInt

    public let lowPriorityFee: BigUInt
    public let marketPriorityFee: BigUInt
    public let fastPriorityFee: BigUInt
}

public struct EthereumTransaction: Decodable {
    let blockHash: String?
    let blockNumber: String?
    let hash: String
    let transactionIndex: String?
}

public struct EthereumTransactionReceipt: Decodable {
    enum Status: Decodable {
        case confirmed
        case failed
        case dropped

        init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)
            switch raw {
            case "0x1": self = .confirmed
            case "0x0": self = .failed
            default: self = .dropped
            }
        }
    }

    let status: Status
    
    enum CodingKeys: CodingKey {
        case status
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.status = try container.decode(Status.self, forKey: .status)
    }
}

struct EthereumPendingTransactionInfo {
    let statuses: [String: PendingTransactionStatus]
    let transactionCount: Int
    let pendingTransactionCount: Int
}
