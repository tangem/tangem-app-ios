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

    func mapToAccountsAwareTokenSelectorItemViewModel(item: AccountsAwareTokenSelectorItem, action: @escaping () -> Void) -> AccountsAwareTokenSelectorItemViewModel? {
        let availabilityTypePublisher: AnyPublisher<AccountsAwareTokenSelectorItem.AvailabilityType, Never>

        switch item.source {
        case .crypto(_, let walletModel):
            availabilityTypePublisher = availabilityProvider.availabilityTypePublisher(
                userWalletInfo: item.userWalletInfo,
                walletModel: walletModel
            )
        case .tangemPay:
            guard availabilityProvider.showsTangemPayItems else { return nil }
            availabilityTypePublisher = .just(output: .available)
        }

        return AccountsAwareTokenSelectorItemViewModel(
            id: item.walletModelId,
            name: item.tokenItem.name,
            symbol: item.tokenItem.currencySymbol,
            tokenIconInfo: TokenIconInfoBuilder().build(
                from: item.tokenItem,
                isCustom: item.isCustom
            ),
            availabilityTypePublisher: availabilityTypePublisher,
            cryptoBalanceProvider: item.cryptoBalanceProvider,
            fiatBalanceProvider: item.fiatBalanceProvider,
            action: action
        )
    }
}
