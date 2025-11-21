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
    private let customerWalletId: String
    private let interactor: TangemPayAuthorizing
    private let keysRepository: KeysRepository

    init(
        customerWalletId: String,
        interactor: TangemPayAuthorizing,
        keysRepository: KeysRepository
    ) {
        self.customerWalletId = customerWalletId
        self.interactor = interactor
        self.keysRepository = keysRepository
    }

    func authorizeWithCustomerWallet() async throws -> VisaAuthorizationTokens {
        let authorizationService = VisaAPIServiceBuilder().buildAuthorizationService()
        let response = try await interactor.authorize(
            customerWalletId: customerWalletId,
            authorizationService: authorizationService
        )
        keysRepository.update(derivations: response.derivationResult)
        return response.tokens
    }
}
