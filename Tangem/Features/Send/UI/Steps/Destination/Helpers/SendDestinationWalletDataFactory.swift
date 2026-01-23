//
//  SendDestinationWalletDataFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct SendDestinationWalletDataFactory {
    func makeWalletData(
        walletModel: any WalletModel,
        analyticsLogger: any SendDestinationAnalyticsLogger
    ) -> SendDestinationInteractorDependenciesProvider.SendingWalletData {
        let walletAddresses = walletModel.addresses.map(\.value)

        return .init(
            walletAddresses: walletAddresses,
            suggestedWallets: SendSuggestedWalletsFactory().makeSuggestedWallets(walletModel: walletModel),
            destinationTransactionHistoryProvider: CommonSendDestinationTransactionHistoryProvider(
                transactionHistoryUpdater: walletModel,
                transactionHistoryMapper: TransactionHistoryMapper(
                    currencySymbol: walletModel.tokenItem.currencySymbol,
                    walletAddresses: walletAddresses,
                    showSign: false,
                    isToken: walletModel.tokenItem.isToken
                )
            ),
            analyticsLogger: analyticsLogger
        )
    }
}
