//
//  CommonAddressBooksProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

/// Real provider backed by the per-wallet `AddressBookManager`. Vends each wallet's verified
/// `AddressBookContact` stream and triggers a load on subscription so the manager publishes the current book.
final class CommonAddressBooksProvider {
    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository
}

// MARK: - AddressBooksProvider

extension CommonAddressBooksProvider: AddressBooksProvider {
    var addressBooks: [AddressBookWallet] {
        userWalletRepository.models
            .filter { !$0.isUserWalletLocked }
            .map { model in
                let manager = model.addressBookManager

                let publisher = manager.contactsPublisher
                    .handleEvents(receiveSubscription: { _ in
                        Task { await manager.load() }
                    })
                    .eraseToAnyPublisher()

                return AddressBookWallet(wallet: model.userWalletInfo, addressBookManager: manager)
            }
    }
}

// MARK: - Factory

extension AddressBooksProvider where Self == CommonAddressBooksProvider {
    static func common() -> Self { .init() }
}
