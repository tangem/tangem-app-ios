//
//  TangemPayKYCInteractor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

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
