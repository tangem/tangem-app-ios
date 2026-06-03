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
    case cardDeactivated(TangemPayAccount)
}

enum TangemPayCachedLocalState: Codable {
    case kycRequired
    case kycDeclined
    case issuingCard
    case failedToIssueCard
    case tangemPayAccount(cardNumberEnd: String?)
    case cardDeactivated(cardNumberEnd: String?)
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

    var isUnavailable: Bool {
        if case .unavailable = self {
            return true
        }
        return false
    }

    var tangemPayAccount: TangemPayAccount? {
        switch self {
        case .tangemPayAccount(let tangemPayAccount), .cardDeactivated(let tangemPayAccount):
            return tangemPayAccount
        default:
            return nil
        }
    }

    var cachedLocalState: TangemPayCachedLocalState? {
        switch self {
        case .kycRequired:
            .kycRequired
        case .kycDeclined:
            .kycDeclined
        case .issuingCard:
            .issuingCard
        case .failedToIssueCard:
            .failedToIssueCard
        case .tangemPayAccount(let account):
            .tangemPayAccount(cardNumberEnd: account.card?.cardNumberEnd)
        case .cardDeactivated(let account):
            .cardDeactivated(cardNumberEnd: account.card?.cardNumberEnd)
        case .loading, .syncNeeded, .syncInProgress, .unavailable:
            nil
        }
    }
}
