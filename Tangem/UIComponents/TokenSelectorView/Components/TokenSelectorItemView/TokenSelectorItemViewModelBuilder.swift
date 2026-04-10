//
//  TokenSelectorItemViewModelBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

struct TokenSelectorItemViewModelBuilder {
    private let availabilityProvider: TokenSelectorItemAvailabilityProvider

    init(availabilityProvider: TokenSelectorItemAvailabilityProvider) {
        self.availabilityProvider = availabilityProvider
    }

    func mapToTokenSelectorItemViewModel(
        item: TokenSelectorItem,
        action: @escaping () -> Void
    ) -> TokenSelectorItemViewModel {
        let availabilityTypePublisher: AnyPublisher<TokenSelectorItem.AvailabilityType, Never>

        if let walletModel = item.kind.walletModel {
            availabilityTypePublisher = availabilityProvider.availabilityTypePublisher(
                userWalletInfo: item.userWalletInfo,
                walletModel: walletModel
            )
        } else {
            availabilityTypePublisher = .just(output: .available)
        }

        return TokenSelectorItemViewModel(
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
