//
//  PaymentAccountAuthorizingCardInteractor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemSdk
import TangemVisa
import TangemLocalization
import TangemPay

final class PaymentAccountAuthorizingCardInteractor: PaymentAccountAuthorizing {
    var syncNeededTitle: String {
        Localization.homeButtonScan
    }

    private let tangemSdk: TangemSdk
    private let filter: SessionFilter
    private let utilities: PaymentAccountUtilities

    init(with cardInfo: CardInfo, utilities: PaymentAccountUtilities) {
        let config = UserWalletConfigFactory().makeConfig(cardInfo: cardInfo)
        tangemSdk = config.makeTangemSdk()
        filter = config.cardSessionFilter
        self.utilities = utilities
    }

    func authorize(
        customerWalletId: String,
        authorizationService: PaymentAccountAuthorizationService
    ) async throws -> PaymentAccountAuthorizingResponse {
        let task = CustomerWalletAuthorizationTask(
            customerWalletId: customerWalletId,
            authorizationService: authorizationService,
            utilities: utilities
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

        return PaymentAccountAuthorizingResponse(
            customerWalletAddress: response.customerWalletAddress,
            tokens: response.tokens,
            derivationResult: response.derivationResult
        )
    }
}
