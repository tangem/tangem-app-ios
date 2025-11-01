//
//  TangemPayAuthorizer.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemVisa
import TangemSdk

final class TangemPayAuthorizer {
    private weak var userWalletModel: UserWalletModel?

    init(userWalletModel: UserWalletModel) {
        self.userWalletModel = userWalletModel
    }

    func authorizeWithCustomerWallet() async throws -> VisaAuthorizationTokens {
        guard let userWalletModel,
              let seedKey = userWalletModel.keysRepository.keys.first(where: { $0.curve == TangemPayUtilities.mandatoryCurve })?.publicKey
        else {
            throw TangemPayAuthorizerError.requiredCurveNotFound
        }

        let task = CustomerWalletAuthorizationTask(
            seedKey: seedKey,
            authorizationService: VisaAPIServiceBuilder().buildAuthorizationService()
        )

        let tangemSdk = userWalletModel.config.makeTangemSdk()

        let response = try await withCheckedThrowingContinuation { continuation in
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

        userWalletModel.keysRepository.update(derivations: response.derivationResult)
        return response.tokens
    }
}

enum TangemPayAuthorizerError: Error {
    case requiredCurveNotFound
}
