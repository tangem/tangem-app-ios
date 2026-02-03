//
//  TangemPayLocalState.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum TangemPayLocalState {
    case initial

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

struct TangemPayManagerWeakReferenceHolder {
    weak var tangemPayManager: TangemPayManager?
}

// MARK: - TangemPayKYCLauncher

protocol TangemPayKYCInteractor {
    var customerId: String? { get }

    func launchKYC(onDidDismiss: (() async -> Void)?) async throws
    func cancelKYC(onFinish: @escaping (Bool) -> Void)
}

extension TangemPayKYCInteractor {
    func launchKYC() async throws {
        try await launchKYC(onDidDismiss: nil)
    }
}

extension TangemPayManagerWeakReferenceHolder: TangemPayKYCInteractor {
    var customerId: String? {
        tangemPayManager?.customerId
    }

    func launchKYC(onDidDismiss: (() async -> Void)?) async throws {
        try await tangemPayManager?.launchKYC(onDidDismiss: onDidDismiss)
    }

    func cancelKYC(onFinish: @escaping (Bool) -> Void) {
        tangemPayManager?.cancelKYC(onFinish: onFinish)
    }
}
