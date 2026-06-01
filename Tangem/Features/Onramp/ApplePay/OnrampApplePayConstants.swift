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

enum OnrampApplePayConstants {
    private static let productionIdentifiers: [String: String] = [
        "mercuryo": "merchant.mercuryo.com.tangem.tangem",
    ]

    private static let sandboxIdentifiers: [String: String] = [
        "mercuryo": "merchant.sandbox.mercuryo.com.tangem.tangem",
    ]

    static func merchantIdentifier(forProviderId providerId: String) -> String? {
        merchantIdentifier(
            forProviderId: providerId,
            isProduction: AppEnvironment.current.isProduction,
            nonProductionMerchantType: FeatureStorage.instance.applePayMerchantType
        )
    }

    static func merchantIdentifier(
        forProviderId providerId: String,
        isProduction: Bool,
        nonProductionMerchantType: ApplePayMerchantType
    ) -> String? {
        let resolved: ApplePayMerchantType = isProduction ? .production : nonProductionMerchantType
        let table = identifiers(for: resolved)
        return table[providerId.lowercased()]
    }

    private static func identifiers(for type: ApplePayMerchantType) -> [String: String] {
        switch type {
        case .production: return productionIdentifiers
        case .sandbox: return sandboxIdentifiers
        }
    }
}
