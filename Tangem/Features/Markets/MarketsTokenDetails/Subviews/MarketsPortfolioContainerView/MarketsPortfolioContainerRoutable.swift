//
//  MarketsPortfolioContainerRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

protocol MarketsPortfolioContainerRoutable: AnyObject {
    func openReceive(userWalletInfo: UserWalletInfo, walletModel: any WalletModel)

    @MainActor
    func openSwap(input: PredefinedSwapParameters, destination: TokenItem)
    func openOnramp(input: SendInput, parameters: PredefinedOnrampParameters)

    @MainActor
    func openMatchedTokenList(
        walletModels: [any WalletModel],
        underivedTokens: [MarketsPortfolioTokenListViewModel.UnderivedToken],
        isTokenAddedEverywhere: Bool,
        addTokenInputData: MarketsAddTokenFlowConfigurationFactory.InputData,
        walletDataProvider: MarketsWalletDataProvider
    )

    func openAddFundsTokenList(walletModels: [any WalletModel], walletDataProvider: MarketsWalletDataProvider)
}
