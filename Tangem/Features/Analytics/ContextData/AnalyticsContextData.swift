//
//  AnalyticsContextData.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import TangemFoundation

struct AnalyticsContextData {
    let productType: Analytics.ProductType
    let batchId: String?
    let firmware: String?
    let baseCurrency: String?
    var userWalletId: UserWalletId?

    var analyticsParams: [Analytics.ParameterKey: String] {
        var params: [Analytics.ParameterKey: String] = [
            .productType: productType.rawValue,
            .basicCurrency: baseCurrency ?? Analytics.ParameterValue.multicurrency.rawValue,
        ]

        if let batchId {
            params[.batch] = batchId
        }

        if let firmware {
            params[.firmware] = firmware
        }

        // You need to send it only if the parameter exists. The default value is not needed.
        if let userWalletId {
            if AppSettings.shared.userWalletIdsWithRing.contains(userWalletId.stringValue) {
                params[.productType] = Analytics.ProductType.ring.rawValue
            }
        }

        return params
    }

    static var mobileWallet = AnalyticsContextData(
        productType: .mobileWallet,
        batchId: nil,
        firmware: nil,
        baseCurrency: nil
    )
}

extension AnalyticsContextData {
    init(card: CardDTO?, productType: Analytics.ProductType, embeddedEntry: StorageEntry?, userWalletId: UserWalletId?) {
        self.productType = productType
        batchId = card?.batchId ?? Analytics.ParameterValue.unknown.rawValue
        firmware = card?.firmwareVersion.stringValue ?? Analytics.ParameterValue.unknown.rawValue
        baseCurrency = embeddedEntry?.tokens.first?.symbol ?? embeddedEntry?.blockchainNetwork.blockchain.currencySymbol
        self.userWalletId = userWalletId
    }
}
