//
//  VirtualAccountLocalState.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum VirtualAccountLocalState {
    case loading

    case syncNeeded
    case syncInProgress

    case unavailable
    case userCreatedWalletBlocked

    case orderCreated
    case kycRequired(PaymentAccountKYCInteractor)
    case kycDeclined(PaymentAccountKYCInteractor)
    case provisioning
    case failedToProvision

    case active(VirtualAccountActiveState)
}

enum VirtualAccountCachedLocalState: Codable {
    case orderCreated
    case kycRequired
    case kycDeclined
    case provisioning
    case failedToProvision
    case active
}

extension VirtualAccountLocalState {
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

    var cachedLocalState: VirtualAccountCachedLocalState? {
        switch self {
        case .orderCreated:
            .orderCreated
        case .kycRequired:
            .kycRequired
        case .kycDeclined:
            .kycDeclined
        case .provisioning:
            .provisioning
        case .failedToProvision:
            .failedToProvision
        case .active:
            .active
        case .loading, .syncNeeded, .syncInProgress, .unavailable, .userCreatedWalletBlocked:
            nil
        }
    }
}
