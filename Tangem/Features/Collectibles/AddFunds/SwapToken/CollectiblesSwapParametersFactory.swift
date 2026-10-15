//
//  CollectiblesSwapParametersFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemCollectibles
import TangemLocalization

enum CollectiblesSwapParametersFactory {
    static func make(
        accountModel: any CollectiblesBalanceSource & BaseAccountModel,
        userWalletInfo: UserWalletInfo,
        walletModelsProvider: MainScreenUIOrderedWalletModelsProvider,
        tokenItem: TokenItem,
        fundingAddress: String
    ) -> PredefinedSwapParameters {
        let destination = CollectiblesDepositReceiveTokenFactory(
            userWalletInfo: userWalletInfo,
            accountModel: accountModel,
            tokenItem: tokenItem,
            fundingAddress: fundingAddress
        )
        .makeReceiveToken()

        let depositCurrency = destination.tokenItem.expressCurrency
        let sourceResolver = CollectiblesDepositSourceResolver(
            userWalletInfo: userWalletInfo,
            walletModelsProvider: walletModelsProvider,
            depositCurrencies: [depositCurrency],
            availabilityChecker: CommonFundingSourceAvailabilityChecker(userWalletInfo: userWalletInfo)
        )

        return .to(
            destination,
            sourceResolver: sourceResolver,
            configuration: SwapFlowConfiguration(
                isPairReversalEnabled: false,
                sourceTokenSelection: .selectable(.filtered(isIncluded: { item in
                    !item.isPayAccount && item.tokenItem.expressCurrency.network == depositCurrency.network
                })),
                receiveTokenSelection: .followsSource(
                    AccountFundingDestinationResolver(candidates: [destination], defaultDestination: destination)
                ),
                summaryTitle: Localization.commonAddFunds
            )
        )
    }
}
