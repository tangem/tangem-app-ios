//
//  TokenDetailsRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemUI

protocol TokenDetailsRoutable: FeeCurrencyNavigating, CloreMigrationRoutable {
    func dismiss()

    func openTransactionDetails(_ data: TransactionDetailsRouteData)
    func cancelTransactionDetailsPresentation()
    func openJointAccountOperationDetails(pendingOperation: JointAccountPendingOperation, userWalletInfo: UserWalletInfo)

    func openYieldModulePromoView(apy: Decimal, isApyBoostPromo: Bool, factory: YieldModuleFlowFactory)
    func openYieldApyBoostStory(apy: Decimal, factory: YieldModuleFlowFactory)
    func openYieldModuleActiveInfo(factory: YieldModuleFlowFactory)
    func openCloreMigration(factory: CloreMigrationModuleFlowFactory)
    func openDynamicAddressesEnterView(
        walletModelDynamicAddressesProvider: WalletModelDynamicAddressesProvider,
        signingActionButtonType: SigningActionButtonViewType,
        analyticsLogger: DynamicAddressesAnalyticsLogger
    )
    func openDynamicAddressesUnavailableSheet(messageType: DynamicAddressesUnavailableSheetViewModel.MessageType)
    func openStakingRegionUnavailableSheet()
    func openDynamicAddressesDisableSheet(
        walletModelDynamicAddressesProvider: WalletModelDynamicAddressesProvider,
        compoundFlowBaseDependenciesFactory: DynamicAddressesCompoundFlowBaseDependenciesFactory,
        analyticsLogger: DynamicAddressesAnalyticsLogger
    )
}
