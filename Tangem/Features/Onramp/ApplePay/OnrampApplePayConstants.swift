//
//  OnrampApplePayConstants.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation

enum OnrampApplePayConstants {
    private static let productionIdentifiers: [String: String] = [
        "mercuryo": "merchant.mercuryo.com.tangem.tangem",
    ]

    private static let sandboxIdentifiers: [String: String] = [
        "mercuryo": "merchant.sandbox.mercuryo.com.tangem.tangem",
    ]

    static func merchantIdentifier(forProviderId providerId: String) -> String? {
        let table = AppEnvironment.current.isProduction ? productionIdentifiers : sandboxIdentifiers
        return table[providerId.lowercased()]
    }
}
