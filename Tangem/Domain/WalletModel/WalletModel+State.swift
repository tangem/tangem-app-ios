//
//  WalletModel+State.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

enum WalletModelState: Hashable, CustomStringConvertible {
    case created
    case loaded(Decimal)
    case loading
    case noAccount(message: String, amountToCreate: Decimal)
    case failed(error: String)

    var isLoading: Bool {
        switch self {
        case .loading, .created:
            return true
        default:
            return false
        }
    }

    var isBlockchainUnreachable: Bool {
        switch self {
        case .failed:
            return true
        default:
            return false
        }
    }

    var errorDescription: String? {
        switch self {
        case .failed(let localizedDescription):
            return localizedDescription
        case .noAccount(let message, _):
            return message
        default:
            return nil
        }
    }

    var failureDescription: String? {
        switch self {
        case .failed(let localizedDescription):
            return localizedDescription
        default:
            return nil
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

enum WalletManagerUpdateResult: Hashable {
    case success
    case noAccount(message: String)
}

enum WalletModelBalanceState {
    case zero
    case positive
}

enum WalletModelTransactionHistoryState: CustomStringConvertible {
    case notSupported
    case notLoaded
    case loading
    case loaded(items: [TransactionRecord])
    case error(Error)

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
