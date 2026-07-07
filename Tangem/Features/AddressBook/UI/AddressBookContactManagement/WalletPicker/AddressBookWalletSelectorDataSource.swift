//
//  AddressBookWalletSelectorDataSource.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct AddressBookWalletSelectorDataSource {
    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository

    let addressBookWallets: [AddressBookWallet]

    private let onSelect: (AddressBookWallet) -> Void

    var itemViewModels: [WalletSelectorItemViewModel] {
        addressBookWallets.compactMap { addressBookWallet in
            guard let userWalletModel = userWalletRepository.models[addressBookWallet.wallet.id] else {
                return nil
            }

            return WalletSelectorItemViewModel(
                userWalletId: userWalletModel.userWalletId,
                cardSetLabel: userWalletModel.config.cardSetLabel,
                isUserWalletLocked: userWalletModel.isUserWalletLocked,
                infoProvider: userWalletModel,
                totalBalancePublisher: userWalletModel.totalBalancePublisher,
                isSelected: false
            ) { userWalletId in
                guard let addressBookWallet = addressBookWallets.first(where: { $0.wallet.id == userWalletId }) else {
                    return
                }

                onSelect(addressBookWallet)
            }
        }
    }

    init(
        addressBookWallets: [AddressBookWallet],
        onSelect: @escaping (AddressBookWallet) -> Void
    ) {
        self.addressBookWallets = addressBookWallets
        self.onSelect = onSelect
    }
}
