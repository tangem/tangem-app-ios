//
//  PolymarketDepositSwapPredefinedParametersBuilder.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemPolymarket

struct PolymarketDepositSwapPredefinedParametersBuilder: SwapPredefinedParametersBuilder {
    let userWalletModel: any UserWalletModel
    let accountModel: any PolymarketAccountModel
    let defaultTarget: PolymarketAccountFundsInteractor.DepositTarget
    let otherTargets: [PolymarketAccountFundsInteractor.DepositTarget]

    func make() -> PredefinedSwapParameters {
        let defaultDestination = makeReceiveToken(depositTarget: defaultTarget)
        let candidates = [defaultDestination] + otherTargets.map { makeReceiveToken(depositTarget: $0) }

        let sourceResolver = PolymarketDepositSourceResolver(
            userWalletModel: userWalletModel,
            depositCurrencies: Set(candidates.map(\.tokenItem.expressCurrency))
        )

        return PredefinedSwapParameters(
            userWalletInfo: defaultDestination.userWalletInfo,
            source: sourceResolver,
            receive: .resolved(defaultDestination),
            configuration: SwapFlowConfiguration(
                isPairReversalEnabled: false,
                sourceTokenSelection: .selectable(.filtered(isIncluded: { !$0.isPayAccount })),
                receiveTokenSelection: .followsSource(
                    AccountFundingDestinationResolver(candidates: candidates, defaultDestination: defaultDestination)
                ),
                summaryTitle: Localization.commonAddFunds
            )
        )
    }
}

// MARK: - Private

private extension PolymarketDepositSwapPredefinedParametersBuilder {
    func makeReceiveToken(depositTarget: PolymarketAccountFundsInteractor.DepositTarget) -> SendSwapableToken {
        PolymarketDepositReceiveTokenFactory(
            userWalletInfo: userWalletModel.userWalletInfo,
            accountModel: accountModel,
            depositTarget: depositTarget
        )
        .makeReceiveToken()
    }
}
