//
//  TangemPayAuthorizingCardInteractor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemPay
import TangemSdk
import TangemVisa

final class TangemPayAuthorizingCardInteractor: TangemPayAuthorizing {
    private let tangemSdk: TangemSdk
    private let filter: SessionFilter
    private let keysRepository: KeysRepository

    init(with cardInfo: CardInfo, keysRepository: KeysRepository) {
        let config = UserWalletConfigFactory().makeConfig(cardInfo: cardInfo)
        tangemSdk = config.makeTangemSdk()
        filter = config.cardSessionFilter
        self.keysRepository = keysRepository
    }

    func authorize(
        customerWalletId: String,
        authorizationService: TangemPayAuthorizationService
    ) async throws {
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

        keysRepository.update(derivations: response.derivationResult)
        try authorizationService.saveTokens(tokens: response.tokens)
    }
}
