//
//  StellarAssetIdParser.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public struct StellarAssetIdParser {
    public init() {}

    public func getAssetCodeAndIssuer(from assetId: String) -> (assetCode: String, issuer: String)? {
        let normalizedAssetId = normalizeAssetId(assetId)
        let parts = normalizedAssetId.split(separator: "-", omittingEmptySubsequences: false).map(String.init)

        guard let assetCode = parts.first,
              let issuer = parts[safe: 1]
        else {
            return nil
        }

        return (assetCode, issuer)
    }

    public func normalizeAssetId(_ assetId: String) -> String {
        let suffix = "-1"
        let baseId = assetId.hasSuffix(suffix) ? String(assetId.dropLast(suffix.count)) : assetId
        return baseId.replacingOccurrences(of: ":", with: "-")
    }
}
