//
//  TangemPayAuthorizer.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemVisa

final class TangemPayAuthorizer {
    let walletModel: any WalletModel

    init(walletModel: any WalletModel) {
        self.walletModel = walletModel
    }

    func authorizeWithCustomerWallet() async throws -> VisaAuthorizationTokens {
        let tangemSdk = TangemSdkDefaultFactory().makeTangemSdk()

        let task = CustomerWalletAuthorizationTask(
            walletPublicKey: walletModel.publicKey,
            walletAddress: walletModel.defaultAddressString,
            authorizationService: VisaAPIServiceBuilder().buildAuthorizationService()
        )

        let tokens = try await withCheckedThrowingContinuation { continuation in
            tangemSdk.startSession(with: task) { result in
                switch result {
                case .success(let hashResponse):
                    continuation.resume(returning: hashResponse)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }

                withExtendedLifetime(task) {}
            }
        }

        return tokens
    }
}
