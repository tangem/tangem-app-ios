//
//  AnalyticsContextDataFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct AnalyticsContextDataFactory {
    func buildContextData(for userWalletModel: UserWalletModel) -> AnalyticsContextData? {
        switch userWalletModel {
        case let model as CardViewModel:
            let config = model.config
            let userWalletId = model.userWalletId

            return AnalyticsContextData(
                card: model.card,
                productType: config.productType,
                userWalletId: userWalletId.value,
                embeddedEntry: config.embeddedBlockchain
            )
        case let lockedUserWallet as LockedUserWallet:
            let config = lockedUserWallet.config
            let cardInfo = lockedUserWallet.userWallet.cardInfo()
            let embeddedEntry = config.embeddedBlockchain
            let baseCurrency = embeddedEntry?.tokens.first?.symbol ?? embeddedEntry?.blockchainNetwork.blockchain.currencySymbol

            return AnalyticsContextData(
                id: nil,
                productType: config.productType,
                batchId: cardInfo.card.batchId,
                firmware: cardInfo.card.firmwareVersion.stringValue,
                baseCurrency: baseCurrency
            )
        default:
            return nil
        }
    }
}
