//
//  VirtualAccountManagerWeakReferenceHolder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

final class VirtualAccountManagerWeakReferenceHolder {
    private weak var virtualAccountManager: VirtualAccountManager?

    init(virtualAccountManager: VirtualAccountManager?) {
        self.virtualAccountManager = virtualAccountManager
    }
}

// MARK: - VirtualAccountManagerWeakReferenceHolder+PaymentAccountKYCInteractor

extension VirtualAccountManagerWeakReferenceHolder: PaymentAccountKYCInteractor {
    var customerId: String? {
        virtualAccountManager?.customerId
    }

    func launchKYC(onDidDismiss: (() async -> Void)?) async throws {
        try await virtualAccountManager?.launchKYC(onDidDismiss: onDidDismiss)
    }

    func cancelKYC(onFinish: @escaping (Bool) -> Void) {
        if let virtualAccountManager {
            virtualAccountManager.cancelKYC(onFinish: onFinish)
        } else {
            onFinish(false)
        }
    }
}
