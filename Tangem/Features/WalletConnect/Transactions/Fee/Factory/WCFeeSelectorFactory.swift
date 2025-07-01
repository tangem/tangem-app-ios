//
//  WCFeeSelectorFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation

final class WCFeeSelectorFactory {
    func createFeeSelector(
        for transaction: WalletConnectEthTransaction,
        walletModel: any WalletModel,
        output: WCFeeInteractorOutput?
    ) -> FeeSelectorContentViewModel {
        let feeProvider = CommonWCFeeProvider()

        let feeInteractor = WCFeeInteractor(
            transaction: transaction,
            walletModel: walletModel,
            feeProvider: feeProvider,
            output: output
        )

        let analytics = WCFeeSelectorAnalytics()
        let customFieldsBuilder = WCFeeSelectorCustomFeeFieldsBuilder()

        return FeeSelectorContentViewModel(
            input: feeInteractor,
            output: feeInteractor,
            analytics: analytics,
            customFieldsBuilder: customFieldsBuilder,
            feeTokenItem: walletModel.feeTokenItem
        )
    }

    func createFeeSelectorFromInteractor(
        feeInteractor: WCFeeInteractor,
        walletModel: any WalletModel
    ) -> FeeSelectorContentViewModel {
        let analytics = WCFeeSelectorAnalytics()
        let customFieldsBuilder = WCFeeSelectorCustomFeeFieldsBuilder()

        return FeeSelectorContentViewModel(
            input: feeInteractor,
            output: feeInteractor,
            analytics: analytics,
            customFieldsBuilder: customFieldsBuilder,
            feeTokenItem: walletModel.feeTokenItem
        )
    }
}
