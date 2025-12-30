//
//  TangemPayAuthorizingCardInteractor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemSdk
import TangemVisa
import TangemLocalization

final class TangemPayAuthorizingCardInteractor: TangemPayAuthorizing {
    var syncNeededTitle: String {
        Localization.homeButtonScan
    }

    private let tangemSdk: TangemSdk
    private let filter: SessionFilter

    init(with cardInfo: CardInfo) {
        let config = UserWalletConfigFactory().makeConfig(cardInfo: cardInfo)
        tangemSdk = config.makeTangemSdk()
        filter = config.cardSessionFilter
    }

    func authorize(
        customerWalletId: String,
        authorizationService: TangemPayAuthorizationService
    ) async throws -> TangemPayAuthorizingResponse {
        let task = CustomerWalletAuthorizationTask(
            customerWalletId: customerWalletId,
            authorizationService: authorizationService
        )

        let response = try await withCheckedThrowingContinuation { continuation in
            tangemSdk.startSession(with: task, filter: filter) { result in
                switch result {
                case .success(let hashResponse):
                    continuation.resume(returning: hashResponse)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }

                withExtendedLifetime(task) {}
            }
        }

        return TangemPayAuthorizingResponse(
            customerWalletAddress: response.customerWalletAddress,
            tokens: response.tokens,
            derivationResult: response.derivationResult
        )
    }
}
