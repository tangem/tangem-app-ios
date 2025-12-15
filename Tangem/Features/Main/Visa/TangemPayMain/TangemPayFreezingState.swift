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

    var isFrozen: Bool {
        switch self {
        case .normal, .freezingInProgress:
            false
        case .frozen, .unfreezingInProgress:
            true
        }
    }

    var isFreezingUnfreezingInProgress: Bool {
        switch self {
        case .normal, .frozen:
            false
        case .freezingInProgress, .unfreezingInProgress:
            true
        }
    }

    var shouldShowUnfreezeButton: Bool {
        switch self {
        case .frozen:
            true
        case .normal, .freezingInProgress, .unfreezingInProgress:
            false
        }
    }

    var shouldDisableActionButtons: Bool {
        switch self {
        case .frozen, .freezingInProgress, .unfreezingInProgress:
            true
        case .normal:
            false
        }
    }
}
