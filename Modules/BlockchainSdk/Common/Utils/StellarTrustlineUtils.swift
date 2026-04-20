//
//  StellarTrustlineUtils.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum StellarTrustlineUtils {
    static func containsTrustline(in trustlines: some Collection<StellarAssetResponse>, assetCode: String, issuer: String) -> Bool {
        trustlines.containsTrustline(for: assetCode, issuer: issuer)
    }

    static func containsTrustline(in trustlines: some Collection<StellarAssetResponse>, for token: Token) -> Bool {
        guard let (code, issuer) = try? StellarAssetIdParser().getAssetCodeAndIssuer(from: token.contractAddress) else {
            return false
        }

        let contains = trustlines.containsTrustline(for: code, issuer: issuer)
        return contains
    }

    static func firstMatchingTrustline(in trustlines: some Collection<StellarAssetResponse>, for token: Token) -> StellarAssetResponse? {
        guard let (code, issuer) = try? StellarAssetIdParser().getAssetCodeAndIssuer(from: token.contractAddress) else {
            return nil
        }

        let match = trustlines.first(where: { $0.matches(currency: code, issuer: issuer) })
        return match
    }

    static func firstMatchingTrustline(
        in trustlines: some Collection<StellarAssetResponse>,
        assetCode: String,
        issuer: String
    ) -> StellarAssetResponse? {
        trustlines.first(where: { $0.matches(currency: assetCode, issuer: issuer) })
    }
}

private extension Collection where Element == StellarAssetResponse {
    func containsTrustline(for assetCode: String, issuer: String) -> Bool {
        contains { $0.matches(currency: assetCode, issuer: issuer) }
    }
}
