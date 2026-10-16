//
//  TangemPayManagerWeakReferenceHolder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemPay

/// Provides scoped access to `TangemPayManager` via protocol conformances.
/// Weak reference avoids retain cycles (stored as associated value in `TangemPayLocalState`).
final class TangemPayManagerWeakReferenceHolder {
    let waitlistService: TangemPayWaitlistService

    private weak var tangemPayManager: TangemPayManager?

    init(tangemPayManager: TangemPayManager, waitlistService: TangemPayWaitlistService) {
        self.tangemPayManager = tangemPayManager
        self.waitlistService = waitlistService
    }
}

// MARK: - TangemPayManagerWeakReferenceHolder+TangemPayKYCInteractor

extension TangemPayManagerWeakReferenceHolder: TangemPayKYCInteractor {
    var customerId: String? {
        tangemPayManager?.customerId
    }

    func launchKYC(onDidDismiss: (() async -> Void)?) async throws {
        try await tangemPayManager?.launchKYC(onDidDismiss: onDidDismiss)
    }

    func cancelKYC(onFinish: @escaping (Bool) -> Void) {
        if let tangemPayManager {
            tangemPayManager.cancelKYC(onFinish: onFinish)
        } else {
            onFinish(false)
        }
    }
}

// MARK: - TangemPayManagerWeakReferenceHolder+TangemPayResidencyInteractor

extension TangemPayManagerWeakReferenceHolder: TangemPayResidencyInteractor {
    func beginResidency() {
        tangemPayManager?.beginResidency()
    }

    func completeResidency(_ result: TangemPayResidencyResult) {
        tangemPayManager?.completeResidency(result)
    }

    func hideAccountFromHome() {
        tangemPayManager?.hideAccountFromHome()
    }
}

// MARK: - TangemPayManagerWeakReferenceHolder+TangemPayTariffPlanSelector

extension TangemPayManagerWeakReferenceHolder: TangemPayTariffPlanSelector {
    func getTariffPlanTransitions() async throws -> TangemPayTariffPlanTransitionsResponse {
        guard let tangemPayManager else {
            throw TangemPayManagerError.managerDeallocated
        }
        return try await tangemPayManager.getTariffPlanTransitions()
    }

    func selectTariffPlan(
        targetTariffPlanId: String,
        transitionType: TangemPayTariffPlanTransition.TransitionType
    ) async throws {
        try await tangemPayManager?.selectTariffPlan(
            targetTariffPlanId: targetTariffPlanId,
            transitionType: transitionType
        )
    }

    func cancelTariffPlanPendingTransition() async throws {
        try await tangemPayManager?.cancelTariffPlanPendingTransition()
    }
}
