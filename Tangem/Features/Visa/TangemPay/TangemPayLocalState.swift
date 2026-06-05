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
    case tangemPayAccount(CardsSummary)
    case cardDeactivated(CardsSummary)
}

extension TangemPayCachedLocalState {
    enum CardsSummary: Codable {
        case single(cardNumberEnd: String)
        case multiple(count: Int)
    }
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
        case .tangemPayAccount(let account), .cardDeactivated(let account):
            return account
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
            account.cardsSummary.map(TangemPayCachedLocalState.tangemPayAccount)
        case .cardDeactivated(let account):
            account.cardsSummary.map(TangemPayCachedLocalState.cardDeactivated)
        case .loading, .syncNeeded, .syncInProgress, .unavailable:
            nil
        }
    }
}

private extension TangemPayAccount {
    var cardsSummary: TangemPayCachedLocalState.CardsSummary? {
        if cards.count > 1 {
            return .multiple(count: cards.count)
        }
        if let cardNumberEnd = card?.cardNumberEnd {
            return .single(cardNumberEnd: cardNumberEnd)
        }
        return nil
    }
}
