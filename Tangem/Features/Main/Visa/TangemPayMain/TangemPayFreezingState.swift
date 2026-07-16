//
//  TangemPayFreezingState.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

enum TangemPayFreezingState {
    case normal
    case freezingInProgress
    case frozen
    case unfreezingInProgress
    /// No card is selected (the management screen is showing an issuing entry). UI sections
    /// driven by freeze state are hidden anyway, but this case keeps the value honest.
    case unavailable

    var isFrozen: Bool {
        switch self {
        case .normal, .freezingInProgress, .unavailable:
            false
        case .frozen, .unfreezingInProgress:
            true
        }
    }

    var isFreezingUnfreezingInProgress: Bool {
        switch self {
        case .normal, .frozen, .unavailable:
            false
        case .freezingInProgress, .unfreezingInProgress:
            true
        }
    }

    var shouldShowUnfreezeButton: Bool {
        switch self {
        case .frozen:
            true
        case .normal, .freezingInProgress, .unfreezingInProgress, .unavailable:
            false
        }
    }

    var shouldDisableActionButtons: Bool {
        switch self {
        case .frozen, .freezingInProgress, .unfreezingInProgress:
            true
        case .normal, .unavailable:
            false
        }
    }
}
