//
//  PolymarketRedeemRecord.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct PolymarketRedeemRecord: Hashable, Sendable {
    public let transactionId: String
    public let state: PolymarketRedeemState
    public let transactionHash: String?

    public init(transactionId: String, state: PolymarketRedeemState, transactionHash: String?) {
        self.transactionId = transactionId
        self.state = state
        self.transactionHash = transactionHash
    }
}

// MARK: - State

public enum PolymarketRedeemState: String, Hashable, Sendable {
    case inProgress = "IN_PROGRESS"
    case confirmed = "CONFIRMED"
    case failed = "FAILED"

    case unknown
}

// MARK: - Decodable protocol conformance

extension PolymarketRedeemState: Decodable {
    public init(from decoder: any Decoder) throws {
        let rawValue = try decoder.singleValueContainer().decode(String.self)
        self = PolymarketRedeemState(rawValue: rawValue) ?? .unknown
    }
}

// MARK: - Convenience extensions

public extension PolymarketRedeemState {
    var isTerminal: Bool {
        switch self {
        case .confirmed, .failed: true
        case .inProgress, .unknown: false
        }
    }
}
