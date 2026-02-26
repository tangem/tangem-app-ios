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
    func openReceive(walletModel: any WalletModel)
    @MainActor
    func openExchange(input: ExpressDependenciesDestinationInput)

    @MainActor
    func openSwap(input: PredefinedSwapParameters, destination: TokenItem)
    func openOnramp(input: SendInput, parameters: PredefinedOnrampParameters)
    func openStaking(input: SendInput, stakingManager: any StakingManager)
    func openYield(input: SendInput, yieldModuleManager: any YieldModuleManager)
}
