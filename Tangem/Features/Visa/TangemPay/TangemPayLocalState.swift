//
//  TangemPayLocalState.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum TangemPayLocalState {
    case loading

    case syncNeeded
    case syncInProgress

    case unavailable

    case kycRequired(TangemPayKYCInteractor)
    case kycDeclined(TangemPayKYCInteractor)
    case issuingCard
    case failedToIssueCard

    case tangemPayAccount(TangemPayAccount)
}

extension TangemPayLocalState {
    var isSyncNeeded: Bool {
        if case .syncNeeded = self {
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
