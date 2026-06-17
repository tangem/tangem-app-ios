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
/// `AddressBookContact` stream; loading is owned by the manager (it loads once on creation).
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
                AddressBookWallet(
                    wallet: model.userWalletInfo,
                    addressBookManager: model.addressBookManager
                )
            }
    }
}

// MARK: - Factory

extension AddressBooksProvider where Self == CommonAddressBooksProvider {
    static func common() -> Self { .init() }
}
