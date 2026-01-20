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
    let authorizationService: TangemPayAuthorizationService
    let keysRepository: KeysRepository

    var state: State {
        stateSubject.value
    }

    var customerWalletId: String {
        userWalletModel?.userWalletId.stringValue ?? ""
    }

    var statePublisher: AnyPublisher<State, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var syncNeededTitle: String {
        userWalletModel?.tangemPayAuthorizingInteractor.syncNeededTitle ?? ""
    }

    private weak var userWalletModel: UserWalletModel?
    private let stateSubject: CurrentValueSubject<State, Never>

    init(
        userWalletModel: UserWalletModel,
        state: State,
        authorizationService: TangemPayAuthorizationService
    ) {
        self.userWalletModel = userWalletModel
        self.authorizationService = authorizationService
        keysRepository = userWalletModel.keysRepository

        stateSubject = CurrentValueSubject(state)
    }

    func authorizeWithCustomerWallet() async throws {
        guard
            let interactor = userWalletModel?.tangemPayAuthorizingInteractor
        else {
            throw Error.interactorNotFound
        }
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

private extension TangemPayAuthorizer {
    enum Error: LocalizedError {
        case interactorNotFound
    }
}
