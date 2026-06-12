//
//  CommonAddressBooksProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

final class CommonAddressBooksProvider {
    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository
}

// MARK: - AddressBooksProvider

extension CommonAddressBooksProvider: AddressBooksProvider {
    var addressBooks: [AddressBookWallet] {
        userWalletRepository.models
            .filter { !$0.isUserWalletLocked }
            .map { userWalletModel in
                AddressBookWallet(
                    wallet: userWalletModel.userWalletInfo,
                    addressBookManager: userWalletModel.addressBookManager
                )
            }
    }
}
