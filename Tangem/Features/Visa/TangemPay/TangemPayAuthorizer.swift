//
//  TangemPayAuthorizer.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemVisa

final class TangemPayAuthorizer {
    let customerWalletId: String
    let authorizationService: TangemPayAuthorizationService
    private let interactor: TangemPayAuthorizing
    private let keysRepository: KeysRepository

    init(
        customerWalletId: String,
        interactor: TangemPayAuthorizing,
        keysRepository: KeysRepository,
        authorizationService: TangemPayAuthorizationService = TangemPayAPIServiceBuilder().buildTangemPayAuthorizationService()
    ) {
        self.customerWalletId = customerWalletId
        self.authorizationService = authorizationService
        self.interactor = interactor
        self.keysRepository = keysRepository
    }

    func authorizeWithCustomerWallet() async throws -> TangemPayAuthorizationTokens {
        let response = try await interactor.authorize(
            customerWalletId: customerWalletId,
            authorizationService: authorizationService
        )
        keysRepository.update(derivations: response.derivationResult)
        return response.tokens
    }
}
