//
//  CollectiblesDepositSwapPredefinedParametersBuilder.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemCollectibles
import TangemLocalization

struct CollectiblesDepositSwapPredefinedParametersBuilder: SwapPredefinedParametersBuilder {
    let accountModel: any CollectiblesBalanceSource & BaseAccountModel
    let userWalletModel: any UserWalletModel
    let tokenItem: TokenItem
    let fundingAddress: String

    func make() -> PredefinedSwapParameters {
        let userWalletInfo = userWalletModel.userWalletInfo
        let destination = CollectiblesDepositReceiveTokenFactory(
            userWalletInfo: userWalletInfo,
            accountModel: accountModel,
            tokenItem: tokenItem,
            fundingAddress: fundingAddress
        )
        .makeReceiveToken()

        let depositCurrency = destination.tokenItem.expressCurrency
        let sourceResolver = CollectiblesDepositSourceResolver(
            userWalletModel: userWalletModel,
            depositCurrencies: [depositCurrency]
        )

        return PredefinedSwapParameters(
            userWalletInfo: destination.userWalletInfo,
            source: sourceResolver,
            receive: .resolved(destination),
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
