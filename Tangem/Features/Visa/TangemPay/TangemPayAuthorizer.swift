//
//  TangemPayAuthorizer.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Combine
import TangemVisa

final class TangemPayAuthorizer {
    let customerWalletId: String
    let authorizationService: TangemPayAuthorizationService
    let keysRepository: KeysRepository

    var state: State {
        stateSubject.value
    }

    var statePublisher: AnyPublisher<State, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    private let interactor: TangemPayAuthorizing
    private let stateSubject: CurrentValueSubject<State, Never>

    init(
        customerWalletId: String,
        interactor: TangemPayAuthorizing,
        keysRepository: KeysRepository,
        state: State,
        authorizationService: TangemPayAuthorizationService = TangemPayAPIServiceBuilder().buildTangemPayAuthorizationService()
    ) {
        self.customerWalletId = customerWalletId
        self.authorizationService = authorizationService
        self.interactor = interactor
        self.keysRepository = keysRepository

        stateSubject = CurrentValueSubject(state)
    }

    func authorizeWithCustomerWallet() async throws {
        let response = try await interactor.authorize(
            customerWalletId: customerWalletId,
            authorizationService: authorizationService
        )
        keysRepository.update(derivations: response.derivationResult)
        stateSubject.send(.authorized(customerWalletAddress: response.customerWalletAddress, tokens: response.tokens))
    }

    func setSyncNeeded() {
        stateSubject.send(.syncNeeded)
    }

    func setUnavailable() {
        stateSubject.send(.unavailable)
    }

    func setAuthorized() {
        guard state.authorized == nil else {
            return
        }

        if let (customerWalletAddress, tokens) = TangemPayUtilities.getCustomerWalletAddressAndAuthorizationTokens(
            customerWalletId: customerWalletId,
            keysRepository: keysRepository
        ) {
            stateSubject.send(.authorized(
                customerWalletAddress: customerWalletAddress,
                tokens: tokens
            ))
        }
    }
}

extension TangemPayAuthorizer {
    enum State {
        case authorized(customerWalletAddress: String, tokens: TangemPayAuthorizationTokens)
        case syncNeeded
        case unavailable

        var authorized: (customerWalletAddress: String, tokens: TangemPayAuthorizationTokens)? {
            switch self {
            case .authorized(let customerWalletAddress, let tokens):
                (customerWalletAddress, tokens)
            case .syncNeeded, .unavailable:
                nil
            }
        }
    }
}
