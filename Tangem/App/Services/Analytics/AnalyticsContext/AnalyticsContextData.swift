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

    var analyticsParams: [Analytics.ParameterKey: String] {
        [
            .productType: productType.rawValue,
            .batch: batchId,
            .firmware: firmware,
            .basicCurrency: baseCurrency ?? Analytics.ParameterValue.multicurrency.rawValue,
        ]
    }
}

extension AnalyticsContextData {
    init(card: CardDTO, productType: Analytics.ProductType, embeddedEntry: StorageEntry?) {
        self.productType = productType
        batchId = card.batchId
        firmware = card.firmwareVersion.stringValue
        baseCurrency = embeddedEntry?.tokens.first?.symbol ?? embeddedEntry?.blockchainNetwork.blockchain.currencySymbol
    }
}
