//
//  TransactionRecord+Math.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation

public extension TransactionRecord.SourceType {
    static func + (lhs: Self, rhs: Self) -> Self {
        let merged = (lhs.list + rhs.list).unique()
        if let single = merged.singleElement {
            return .single(single)
        }
        return .multiple(merged)
    }

    private var list: [TransactionRecord.Source] {
        switch self {
        case .single(let source): return [source]
        case .multiple(let sources): return sources
        }
    }
}

public extension TransactionRecord.DestinationType {
    static func + (lhs: Self, rhs: Self) -> Self {
        let merged = (lhs.list + rhs.list).unique()
        if let single = merged.singleElement {
            return .single(single)
        }
        return .multiple(merged)
    }

    private var list: [TransactionRecord.Destination] {
        switch self {
        case .single(let destination): return [destination]
        case .multiple(let destinations): return destinations
        }
    }
}
