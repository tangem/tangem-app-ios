//
//  PolymarketWithdrawState.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public enum PolymarketWithdrawState: String, Hashable, Sendable {
    case inProgress = "IN_PROGRESS"
    case confirmed = "CONFIRMED"
    case failed = "FAILED"

    case unknown
}

// MARK: - Decodable protocol conformance

extension PolymarketWithdrawState: Decodable {
    public init(from decoder: any Decoder) throws {
        let rawValue = try decoder.singleValueContainer().decode(String.self)
        self = PolymarketWithdrawState(rawValue: rawValue) ?? .unknown
    }
}

// MARK: - Convenience extensions

public extension PolymarketWithdrawState {
    var isTerminal: Bool {
        switch self {
        case .confirmed, .failed: true
        case .inProgress, .unknown: false
        }
    }
}
