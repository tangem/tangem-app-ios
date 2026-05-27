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

    static func containsTrustline(in trustlines: some Collection<XRPTrustLine>, for token: Token) -> Bool {
        guard let (currency, issuer) = try? XRPAssetIdParser().getCurrencyCodeAndIssuer(from: token.contractAddress) else {
            return false
        }

        return trustlines.containsTrustline(for: currency, issuer: issuer)
    }

    static func balance(in trustlines: some Collection<XRPTrustLine>, currency: String, issuer: String) -> String? {
        trustlines.balance(for: currency, issuer: issuer)
    }

    static func firstMatchingTrustline(in trustlines: some Collection<XRPTrustLine>, for token: Token) -> XRPTrustLine? {
        guard let (currency, issuer) = try? XRPAssetIdParser().getCurrencyCodeAndIssuer(from: token.contractAddress) else {
            return nil
        }

        return trustlines.first(where: { $0.matches(currency: currency, issuer: issuer) })
    }

    static func firstMatchingTrustline(in trustlines: some Collection<XRPTrustLine>, currency: String, issuer: String) -> XRPTrustLine? {
        trustlines.first(where: { $0.matches(currency: currency, issuer: issuer) })
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
