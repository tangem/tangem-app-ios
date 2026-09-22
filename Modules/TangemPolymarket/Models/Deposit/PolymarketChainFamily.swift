//
//  PolymarketChainFamily.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public enum PolymarketChainFamily: Hashable, Sendable, CaseIterable {
    case evm
    case svm
    case btc
    case tron
}

// MARK: - Chain id

public extension PolymarketChainFamily {
    init?(chainId: String) {
        switch chainId {
        case Constants.solanaChainId: self = .svm
        case Constants.tronChainId: self = .tron
        case Constants.bitcoinChainId: self = .btc
        case _ where Constants.evmChainIds.contains(chainId): self = .evm
        default: return nil
        }
    }
}

// MARK: - Constants

private extension PolymarketChainFamily {
    enum Constants {
        static let solanaChainId = "1151111081099710"
        static let tronChainId = "728126428"
        static let bitcoinChainId = "8253038"

        static let evmChainIds: Set<String> = [
            "1",
            "10",
            "56",
            "137",
            "143",
            "999",
            "4663",
            "8453",
            "42161",
            "57073",
        ]
    }
}
