//
//  TangemPayManagerWeakReferenceHolder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// Provides scoped access to `TangemPayManager` via protocol conformances.
/// Weak reference avoids retain cycles (stored as associated value in `TangemPayLocalState`).
final class TangemPayManagerWeakReferenceHolder {
    private weak var tangemPayManager: TangemPayManager?

    init(tangemPayManager: TangemPayManager?) {
        self.tangemPayManager = tangemPayManager
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
