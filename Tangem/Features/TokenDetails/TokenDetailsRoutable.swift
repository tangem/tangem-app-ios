//
//  TokenDetailsRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol TokenDetailsRoutable: FeeCurrencyNavigating, CloreMigrationRoutable {
    func dismiss()

    func openYieldModulePromoView(apy: Decimal, isApyBoostPromo: Bool, factory: YieldModuleFlowFactory)
    func openYieldApyBoostStory(apy: Decimal, factory: YieldModuleFlowFactory)
    func openYieldModuleActiveInfo(factory: YieldModuleFlowFactory)
    func openYieldBalanceInfo(factory: YieldModuleFlowFactory)
    func openCloreMigration(factory: CloreMigrationModuleFlowFactory)
    func openDynamicAddressesEnterView(
        walletModelDynamicAddressesProvider: WalletModelDynamicAddressesProvider,
        analyticsLogger: DynamicAddressesAnalyticsLogger
    )
    func openDynamicAddressesUnavailableSheet(messageType: DynamicAddressesUnavailableSheetViewModel.MessageType)
    func openDynamicAddressesDisableSheet(
        walletModelDynamicAddressesProvider: WalletModelDynamicAddressesProvider,
        compoundFlowBaseDependenciesFactory: DynamicAddressesCompoundFlowBaseDependenciesFactory,
        analyticsLogger: DynamicAddressesAnalyticsLogger
    )
}
