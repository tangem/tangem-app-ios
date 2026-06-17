//
//  OnrampApplePayConstants.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation

enum ApplePayMerchantType: String, CaseIterable {
    case production
    case sandbox
}

struct ApplePayProviderConfig: Equatable {
    let merchantIdentifier: String
    let countryCode: String
    let summaryItemLabel: String
}

enum OnrampApplePayConstants {
    private static let productionConfigs: [String: ApplePayProviderConfig] = [
        "mercuryo": ApplePayProviderConfig(
            merchantIdentifier: "merchant.mercuryo.com.tangem.tangem",
            countryCode: "LT",
            summaryItemLabel: "Pay Mercuryo (via Tangem)"
        ),
    ]

    private static let sandboxConfigs: [String: ApplePayProviderConfig] = [
        "mercuryo": ApplePayProviderConfig(
            merchantIdentifier: "merchant.sandbox.mercuryo.com.tangem.tangem",
            countryCode: "LT",
            summaryItemLabel: "Pay Mercuryo (via Tangem)"
        ),
    ]

    static func config(forProviderId providerId: String) -> ApplePayProviderConfig? {
        config(
            forProviderId: providerId,
            isProduction: AppEnvironment.current.isProduction,
            nonProductionMerchantType: FeatureStorage.instance.applePayMerchantType
        )
    }

    static func config(
        forProviderId providerId: String,
        isProduction: Bool,
        nonProductionMerchantType: ApplePayMerchantType
    ) -> ApplePayProviderConfig? {
        let resolved: ApplePayMerchantType = isProduction ? .production : nonProductionMerchantType
        let table = configs(for: resolved)
        return table[providerId.lowercased()]
    }

    private static func configs(for type: ApplePayMerchantType) -> [String: ApplePayProviderConfig] {
        switch type {
        case .production: return productionConfigs
        case .sandbox: return sandboxConfigs
        }
    }
}
