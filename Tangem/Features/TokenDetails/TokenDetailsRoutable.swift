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

    func openYieldModulePromoView(apy: Decimal, factory: YieldModuleFlowFactory)
    func openYieldModuleActiveInfo(factory: YieldModuleFlowFactory)
    func openYieldBalanceInfo(factory: YieldModuleFlowFactory)
    func openCloreMigration(factory: CloreMigrationModuleFlowFactory)
    func openDynamicAddressesEnterView(dynamicAddressesManager: DynamicAddressesManager, walletModelUpdater: WalletModelUpdater)
    func openDynamicAddressesUnavailableSheet()
    func openDynamicAddressesDisableSheet(dynamicAddressesManager: DynamicAddressesManager, walletModelUpdater: WalletModelUpdater)
    func openDynamicAddressesCompoundTransaction(input: SendInput, amount: BSDKAmount, destination: String)
}
