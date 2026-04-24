//
//  StellarAssetIdParser.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public struct StellarAssetIdParser {
    public init() {}

    public func getAssetCodeAndIssuer(from assetId: String) throws -> (assetCode: String, issuer: String) {
        let normalizedAssetId = normalizeAssetId(assetId)
        let parts = normalizedAssetId.split(separator: "-", omittingEmptySubsequences: false).map(String.init)

        guard parts.count == 2 else {
            throw StellarError.failedParseAssetId
        }

        return (parts.first!, parts[1])
    }

    public func normalizeAssetId(_ assetId: String) -> String {
        let suffix = "-1"
        let baseId = assetId.hasSuffix(suffix) ? String(assetId.dropLast(suffix.count)) : assetId
        return baseId.replacingOccurrences(of: ":", with: "-")
    }
}
