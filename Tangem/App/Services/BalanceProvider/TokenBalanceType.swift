//
//  TokenBalanceType.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - TokenBalanceType

enum TokenBalanceType: Hashable {
    // No derivation / Don't start loading yet
    case empty(EmptyReason)
    // "Skeleton" or "New animation"
    case loading(Cached?)
    // "Cached" or "-"
    // The date on which the balance would be relevant
    case failure(Cached?)
    // All good
    case loaded(Decimal)
}

// MARK: - TokenBalanceType+

extension TokenBalanceType {
    var value: Decimal? {
        switch self {
        case .empty: nil
        case .loading(let cached): cached?.balance
        case .failure(let cached): cached?.balance
        case .loaded(let value): value
        }
    }

    var cached: TokenBalanceType.Cached? {
        switch self {
        case .empty: nil
        case .loading(let cached): cached
        case .failure(let cached): cached
        case .loaded(let value): nil
        }
    }

    var isLoading: Bool {
        switch self {
        case .loading: true
        default: false
        }
    }

    var isFailure: Bool {
        switch self {
        case .failure: true
        default: false
        }
    }
}

// MARK: - CustomStringConvertible

extension TokenBalanceType: CustomStringConvertible {
    var description: String {
        switch self {
        case .empty(let reason): "Empty \(reason)"
        case .loading(let cached): "Loading cached: \(String(describing: cached))"
        case .failure(let cached): "Failure cached: \(String(describing: cached))"
        case .loaded(let balance): "Loaded: \(balance)"
        }
    }
}

// MARK: - Models

extension TokenBalanceType {
    enum EmptyReason: Hashable {
        /// The data is not loaded yet
        case noData
        /// No derivation so no balance
        case noDerivation
        /// Custom token so no rate
        case custom
        /// No account (XRP) so no balance
        case noAccount(message: String)
    }

    struct Cached: Hashable {
        let balance: Decimal
        let date: Date
    }
}
