//
//  PaymentAccountViewState.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemUI

enum PaymentAccountViewState {
    case skeleton
    case kycInProgress
    case kycDeclined
    case pendingActivation
    case activationFailed
    case normal(subtitle: String?, balance: LoadableBalanceView.State)
    case syncNeeded
    case unavailable(cached: CachedDisplayData? = nil)
    case rootedDevice

    var isFullyVisible: Bool {
        switch self {
        case .kycInProgress, .pendingActivation, .activationFailed, .normal, .skeleton, .kycDeclined:
            true
        case .syncNeeded, .unavailable, .rootedDevice:
            false
        }
    }

    var isSkeleton: Bool {
        if case .skeleton = self {
            return true
        }
        return false
    }
}

// MARK: - Nested Types

extension PaymentAccountViewState {
    struct CachedDisplayData {
        let subtitle: String?
        let trailing: Trailing

        enum Trailing {
            case empty
            case warningIcon
            case balance(LoadableBalanceView.State)
        }
    }
}
