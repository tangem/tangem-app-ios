//
//  PolymarketSwapParametersFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

struct PolymarketSwapParametersFactory {
    let userWalletInfo: UserWalletInfo
    let walletModelsProvider: MainScreenUIOrderedWalletModelsProvider
    let accountModel: any PolymarketAccountModel

    func make(depositTarget: PolymarketAccountFundsInteractor.DepositTarget) -> PredefinedSwapParameters {
        let receiveToken = PolymarketDepositReceiveTokenFactory(
            userWalletInfo: userWalletInfo,
            accountModel: accountModel,
            depositTarget: depositTarget
        )
        .makeReceiveToken()

        let sourceResolver = PolymarketDepositSourceResolver(
            userWalletInfo: userWalletInfo,
            walletModelsProvider: walletModelsProvider,
            depositCurrency: receiveToken.tokenItem.expressCurrency,
            availabilityChecker: CommonFundingSourceAvailabilityChecker(userWalletInfo: userWalletInfo)
        )

        return .to(
            receiveToken,
            sourceResolver: sourceResolver,
            configuration: SwapFlowConfiguration(
                isPairReversalEnabled: false,
                sourceTokenSelection: .unrestricted,
                receiveTokenSelection: .followsSource(
                    PolymarketDepositDestinationResolver(destination: receiveToken)
                ),
                summaryTitle: Localization.commonAddFunds
            )
        )
    }
}
