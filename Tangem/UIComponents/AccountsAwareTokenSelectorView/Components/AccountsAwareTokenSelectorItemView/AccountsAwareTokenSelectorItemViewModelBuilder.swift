//
//  AccountsAwareTokenSelectorItemViewModelBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

struct AccountsAwareTokenSelectorItemViewModelBuilder {
    private let availabilityProvider: AccountsAwareTokenSelectorItemAvailabilityProvider

    init(availabilityProvider: AccountsAwareTokenSelectorItemAvailabilityProvider) {
        self.availabilityProvider = availabilityProvider
    }

    func mapToAccountsAwareTokenSelectorItemViewModel(
        item: AccountsAwareTokenSelectorItem,
        action: @escaping () -> Void
    ) -> AccountsAwareTokenSelectorItemViewModel {
        let availabilityTypePublisher: AnyPublisher<AccountsAwareTokenSelectorItem.AvailabilityType, Never>

        if let walletModel = item.kind.walletModel {
            availabilityTypePublisher = availabilityProvider.availabilityTypePublisher(
                userWalletInfo: item.userWalletInfo,
                walletModel: walletModel
            )
        } else {
            availabilityTypePublisher = .just(output: .available)
        }

        return AccountsAwareTokenSelectorItemViewModel(
            id: WalletModelId(tokenItem: item.tokenItem),
            name: item.tokenItem.name,
            symbol: item.tokenItem.currencySymbol,
            tokenIconInfo: TokenIconInfoBuilder().build(
                from: item.tokenItem,
                isCustom: item.kind.walletModel?.isCustom ?? false
            ),
            availabilityTypePublisher: availabilityTypePublisher,
            cryptoBalanceProvider: item.cryptoBalanceProvider,
            fiatBalanceProvider: item.fiatBalanceProvider,
            action: action
        )
    }
}
