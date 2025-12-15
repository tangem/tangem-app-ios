//
//  TangemPayAccountProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

// [REDACTED_TODO_COMMENT]
// Remove it and setup it before UserWalletModel was created
protocol TangemPayAccountProviderSetupable: TangemPayAccountProvider {
    func setup(for userWalletModel: any UserWalletModel)
}

protocol TangemPayAccountProvider {
    var tangemPayAccount: TangemPayAccount? { get }
    var tangemPayAccountPublisher: AnyPublisher<TangemPayAccount?, Never> { get }
}

class CommonTangemPayAccountProvider {
    private let tangemPayAccountSubject: CurrentValueSubject<TangemPayAccount?, Never> = .init(nil)
    private var tangemPayAccountCancellable: Cancellable?

    init() {}
}

// MARK: - TangemPayAccountProvider

extension CommonTangemPayAccountProvider: TangemPayAccountProviderSetupable {
    func setup(for userWalletModel: any UserWalletModel) {
        Task { [self] in
            let builder = TangemPayAccountBuilder()
            let tangemPayAccount = try? await builder.makeTangemPayAccount(
                authorizerType: .availabilityService,
                userWalletModel: userWalletModel
            )

            if let tangemPayAccount {
                tangemPayAccountSubject.send(tangemPayAccount)
            } else {
                // Make it possible to create TangemPayAccount from offer screen
                tangemPayAccountCancellable = userWalletModel.updatePublisher
                    .compactMap(\.tangemPayAccount)
                    .first()
                    .sink(receiveValue: tangemPayAccountSubject.send)
            }
        }
    }
}

// MARK: - TangemPayAccountProvider

extension CommonTangemPayAccountProvider: TangemPayAccountProvider {
    var tangemPayAccountPublisher: AnyPublisher<TangemPayAccount?, Never> {
        tangemPayAccountSubject.eraseToAnyPublisher()
    }

    var tangemPayAccount: TangemPayAccount? {
        tangemPayAccountSubject.value
    }
}
