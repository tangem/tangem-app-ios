//
//  TangemPayLocalState.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum TangemPayLocalState {
    case initial

    case syncNeeded
    case syncInProgress

    case unavailable

    case kycRequired
    case kycDeclined
    case issuingCard
    case failedToIssueCard

    case tangemPayAccount(TangemPayAccount)
}

extension TangemPayLocalState {
    var isInitial: Bool {
        if case .initial = self {
            return true
        }
        return false
    }

    var isSyncInProgress: Bool {
        if case .syncInProgress = self {
            return true
        }
        return false
    }

    var tangemPayAccount: TangemPayAccount? {
        if case .tangemPayAccount(let tangemPayAccount) = self {
            return tangemPayAccount
        }
        return nil
    }
}
