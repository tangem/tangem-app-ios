//
//  AnalyticsContextData.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct AnalyticsContextData {
    let productType: Analytics.ProductType
    let batchId: String
    let firmware: String
    let baseCurrency: String?
    var userWalletId: UserWalletId?

    var analyticsParams: [Analytics.ParameterKey: String] {
        [
            .userWalletId: userWalletId?.stringValue ?? Constants.unknownedUserWalletId,
            .productType: productType.rawValue,
            .batch: batchId,
            .firmware: firmware,
            .basicCurrency: baseCurrency ?? Analytics.ParameterValue.multicurrency.rawValue,
        ]
    }
}

extension AnalyticsContextData {
    init(card: CardDTO, productType: Analytics.ProductType, embeddedEntry: StorageEntry?, userWalletId: UserWalletId?) {
        self.productType = productType
        batchId = card.batchId
        firmware = card.firmwareVersion.stringValue
        baseCurrency = embeddedEntry?.tokens.first?.symbol ?? embeddedEntry?.blockchainNetwork.blockchain.currencySymbol
        self.userWalletId = userWalletId
    }
}

extension AnalyticsContextData {
    enum Constants {
        static let unknownedUserWalletId: String = "Unknowned user wallet ID"
    }
}
