//
//  StellarTrustlineUtils.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum StellarTrustlineUtils {
    static func containsTrustline<T: Collection>(
        in trustlines: T,
        assetCode: String,
        issuer: String
    ) -> Bool where T.Element == StellarAssetResponse {
        trustlines.containsTrustline(for: assetCode, issuer: issuer)
    }

    static func containsTrustline<T: Collection>(in trustlines: T, for token: Token) -> Bool where T.Element == StellarAssetResponse {
        guard let (code, issuer) = try? StellarAssetIdParser().getAssetCodeAndIssuer(from: token.contractAddress) else {
            return false
        }

        let contains = trustlines.containsTrustline(for: code, issuer: issuer)
        return contains
    }

    static func firstMatchingTrustline<T: Collection>(
        in trustlines: T,
        for token: Token
    ) -> StellarAssetResponse? where T.Element == StellarAssetResponse {
        guard let (code, issuer) = try? StellarAssetIdParser().getAssetCodeAndIssuer(from: token.contractAddress) else {
            return nil
        }

        let match = trustlines.first(where: { $0.matches(currency: code, issuer: issuer) })
        return match
    }

    static func firstMatchingTrustline<T: Collection>(
        in trustlines: T,
        assetCode: String,
        issuer: String
    ) -> StellarAssetResponse? where T.Element == StellarAssetResponse {
        trustlines.first(where: { $0.matches(currency: assetCode, issuer: issuer) })
    }
}

private extension Collection where Element == StellarAssetResponse {
    func containsTrustline(for assetCode: String, issuer: String) -> Bool {
        contains { $0.matches(currency: assetCode, issuer: issuer) }
    }
}
