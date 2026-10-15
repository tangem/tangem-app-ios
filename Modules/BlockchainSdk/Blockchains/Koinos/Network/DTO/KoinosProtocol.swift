//
//  KoinosProtocol.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum KoinosProtocol {
    struct TransactionBlock: Decodable {
        let transaction: Transaction
        let containingBlocks: [String]
    }

    struct Transaction: Equatable, Codable {
        let header: TransactionHeader
        let id: String
        let operations: [Operation]
        let signatures: [String]
    }

    struct TransactionHeader: Equatable, Codable {
        let chainId: String
        let rcLimit: String
        let nonce: String
        let operationMerkleRoot: String
        let payer: String
        let payee: String?
    }

    struct Operation: Equatable, Codable {
        let callContract: CallContractOperation
    }

    struct CallContractOperation: Equatable, Codable {
        let contractId: String
        let entryPoint: Int
        let args: String
    }

    struct TransactionReceipt: Equatable, Decodable {
        let id: String
        let payer: String
        let maxPayerRc: String
        let rcLimit: String
        let rcUsed: String
        let diskStorageUsed: String?
        let networkBandwidthUsed: String?
        let computeBandwidthUsed: String?
        let reverted: Bool?
        let events: [EventData]
    }

    struct EventData: Equatable, Decodable {
        let sequence: Int?
        let source: String
        let name: String
        let data: String
        let impacted: [String]
    }

    struct ResourceLimitData: Decodable {
        let diskStorageLimit: String
        let diskStorageCost: String
        let networkBandwidthLimit: String
        let networkBandwidthCost: String
        let computeBandwidthLimit: String
        let computeBandwidthCost: String
    }
}
