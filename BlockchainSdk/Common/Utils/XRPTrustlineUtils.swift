//
//  XRPTrustlineUtils.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum XRPTrustlineUtils {
    static func containsTrustline<T: Collection>(in trustlines: T, currency: String, issuer: String) -> Bool where T.Element == XRPTrustLine {
        trustlines.containsTrustline(for: currency, issuer: issuer)
    }

    static func balance<T: Collection>(in trustlines: T, currency: String, issuer: String) -> String? where T.Element == XRPTrustLine {
        trustlines.balance(for: currency, issuer: issuer)
    }
}

private extension Collection where Element == XRPTrustLine {
    func containsTrustline(for currency: String, issuer: String) -> Bool {
        contains { $0.matches(currency: currency, issuer: issuer) }
    }

    func balance(for currency: String, issuer: String) -> String? {
        first { $0.matches(currency: currency, issuer: issuer) }?.balance
    }
}
