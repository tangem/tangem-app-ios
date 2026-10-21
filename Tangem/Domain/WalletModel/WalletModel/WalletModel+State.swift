//
//  WalletModel+State.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation

enum WalletModelState: Hashable, CustomStringConvertible {
    case created
    case loaded(Decimal)
    case loading
    case noAccount(message: String, amountToCreate: Decimal)
    case failed(error: String)

    var isBlockchainUnreachable: Bool {
        switch self {
        case .failed:
            return true
        default:
            return false
        }
    }

    var description: String {
        switch self {
        case .created: "Created"
        case .loaded: "Loaded"
        case .loading: "Loading"
        case .noAccount(let message, _): "No account \(message)"
        case .failed(let error): "Failed \(error)"
        }
    }
}

enum WalletModelTransactionHistoryState: CustomStringConvertible {
    case notSupported
    case notLoaded
    case loading
    case loaded(items: [TransactionRecord])
    case error(Error)

    /// `.notSupported` is excluded: the history is gone for this wallet entirely, so it has to reach the UI
    /// instead of being held back. `.notLoaded` is not — a refresh resets the service to it on chains with
    /// dynamic addresses, so holding it back is what keeps the list alive there.
    var preservesPreviousContent: Bool {
        switch self {
        case .loading, .error, .notLoaded:
            return true
        case .loaded(let items):
            return items.isEmpty
        case .notSupported:
            return false
        }
    }

    var description: String {
        switch self {
        case .notSupported:
            return "TransactionHistoryState.notSupported"
        case .notLoaded:
            return "TransactionHistoryState.notLoaded"
        case .loading:
            return "TransactionHistoryState.loading"
        case .loaded(let items):
            return "TransactionHistoryState.loaded with items: \(items.count)"
        case .error(let error):
            return "TransactionHistoryState.error with \(error.localizedDescription)"
        }
    }
}
