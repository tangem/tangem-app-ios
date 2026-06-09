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
import TangemPay

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
    ) async throws(TangemPayAuthorizationError) -> TangemPayAuthorizingResponse {
        let task = CustomerWalletAuthorizationTask(
            customerWalletId: customerWalletId,
            authorizationService: authorizationService
        )

        let response: CustomerWalletAuthorizationTask.Response = await withCheckedContinuation { continuation in
            tangemSdk.startSession(with: task, filter: filter) { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(returning: .init(
                        authorizationError: error,
                        derivationResult: [:]
                    ))
                }

                withExtendedLifetime(task) {}
            }
        }

        switch response.authorizationResult {
        case .success(let authData):
            return TangemPayAuthorizingResponse(
                customerWalletAddress: authData.customerWalletAddress,
                tokens: authData.tokens,
                derivationResult: response.derivationResult
            )
        case .failure(let error):
            throw TangemPayAuthorizationError(
                underlyingError: error,
                derivationResult: response.derivationResult
            )
        }
    }
}
