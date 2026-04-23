//
//  KaspaTransactionHistoryResponse.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// just namespace to avoid conflict with BlockchainSdk -> KaspaTransaction
enum KaspaTransactionHistoryResponse {
    struct Transaction: Decodable {
        let transactionId: String?
        let hash: String?
        let blockTime: Date?
        let isAccepted: Bool?

        @LossyArray private(set) var inputs: [Input]
        @LossyArray private(set) var outputs: [Output]

        struct Input: Decodable {
            let previousOutpointAddress: String?
            let previousOutpointAmount: Int?
        }

        struct Output: Decodable {
            let amount: Int?
            let scriptPublicKeyAddress: String?
        }
    }
}

extension KaspaTransactionHistoryResponse.Transaction {
    enum CodingKeys: String, CodingKey {
        case transactionId
        case hash
        case blockTime
        case isAccepted
        case inputs
        case outputs
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        transactionId = try container.decodeIfPresent(String.self, forKey: .transactionId)
        hash = try container.decodeIfPresent(String.self, forKey: .hash)
        blockTime = try container.decodeIfPresent(Date.self, forKey: .blockTime)
        isAccepted = try container.decodeIfPresent(Bool.self, forKey: .isAccepted)
        inputs = (try container.decodeIfPresent(LossyArray<Input>.self, forKey: .inputs))?.wrappedValue ?? []
        outputs = (try container.decodeIfPresent(LossyArray<Output>.self, forKey: .outputs))?.wrappedValue ?? []
    }
}
