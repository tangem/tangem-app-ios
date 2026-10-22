//
//  JointAccountsDTO.Response.HistoryOperation.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension JointAccountsDTO.Response {
    struct HistoryOperation {
        let operation: JointAccountsDTO.Response.Operation
        let cryptoAccountId: String
        let safeAddress: String
        let txHash: String?
        let finishedAt: String?
        let cancelReason: String?
    }
}

// MARK: - Decodable

extension JointAccountsDTO.Response.HistoryOperation: Decodable {
    private enum CodingKeys: String, CodingKey {
        case cryptoAccountId
        case safeAddress
        case txHash
        case finishedAt
        case cancelReason
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        operation = try JointAccountsDTO.Response.Operation(from: decoder)
        cryptoAccountId = try container.decode(String.self, forKey: .cryptoAccountId)
        safeAddress = try container.decode(String.self, forKey: .safeAddress)
        txHash = try container.decodeIfPresent(String.self, forKey: .txHash)
        finishedAt = try container.decodeIfPresent(String.self, forKey: .finishedAt)
        cancelReason = try container.decodeIfPresent(String.self, forKey: .cancelReason)
    }
}
