//
//  CryptoAccountsNetworkServiceUpdateType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct CryptoAccountsNetworkServiceUpdateType: OptionSet {
    let rawValue: Int

    static let accounts = Self(rawValue: 1 << 0)
    static let tokens = Self(rawValue: 1 << 1)
}

// MARK: - Convenience extensions

extension CryptoAccountsNetworkServiceUpdateType {
    var all: Self {
        [
            .accounts,
            .tokens,
        ]
    }
}
