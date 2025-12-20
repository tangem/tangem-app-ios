//
//  AccountsAwareTokenSelectorItemViewModelBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct AccountsAwareTokenSelectorItemViewModelBuilder {
    private let availabilityProvider: AccountsAwareTokenSelectorItemAvailabilityProvider

    init(availabilityProvider: AccountsAwareTokenSelectorItemAvailabilityProvider) {
        self.availabilityProvider = availabilityProvider
    }

    func mapToAccountsAwareTokenSelectorItemViewModel(item: AccountsAwareTokenSelectorItem, action: @escaping () -> Void) -> AccountsAwareTokenSelectorItemViewModel {
        AccountsAwareTokenSelectorItemViewModel(
            id: item.walletModel.id,
            name: item.walletModel.tokenItem.name,
            symbol: item.walletModel.tokenItem.currencySymbol,
            tokenIconInfo: TokenIconInfoBuilder().build(
                from: item.walletModel.tokenItem,
                isCustom: item.walletModel.isCustom
            ),
            availabilityTypePublisher: availabilityProvider.availabilityTypePublisher(
                userWalletInfo: item.userWalletInfo,
                walletModel: item.walletModel
            ),
            cryptoBalanceProvider: item.cryptoBalanceProvider,
            fiatBalanceProvider: item.fiatBalanceProvider,
            action: action
        )
    }
}
