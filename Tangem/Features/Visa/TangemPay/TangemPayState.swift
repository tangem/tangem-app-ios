//
//  TangemPayState.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemMacro

@CaseFlagable
enum TangemPayState {
    case initial

    case syncNeeded
    case syncInProgress

    case unavailable

    case kyc
    case issuingCard(orderId: String)
    case failedToIssueCard

    case tangemPayAccount(TangemPayAccount)
}

extension TangemPayState {
    var tangemPayAccount: TangemPayAccount? {
        if case .tangemPayAccount(let tangemPayAccount) = self {
            return tangemPayAccount
        }
        return nil
    }
}
