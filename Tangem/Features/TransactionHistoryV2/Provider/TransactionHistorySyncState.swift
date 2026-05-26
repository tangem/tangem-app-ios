//
//  TransactionHistorySyncState.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum TransactionHistorySyncState: Sendable {
    case idle(IdleReason)
    case syncing(Kind)
    case failed(Failure)
}

extension TransactionHistorySyncState {
    enum Kind: Sendable, Hashable {
        case initial
        case delta
        case userInitiated(UserInitiatedSyncKind)
    }

    enum IdleReason: Sendable, Hashable {
        case waitingForInitial
        case ready
        case noHistory
    }

    struct Failure: Sendable {
        enum Reason: Sendable {
            case cursorReset
            case partialFailure(failedProviders: [String])
            case transport(message: String)
            case server(statusCode: Int, message: String?)
        }

        let reason: Reason
        let syncKind: Kind
    }
}
