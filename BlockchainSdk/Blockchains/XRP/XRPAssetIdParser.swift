//
//  XRPAssetIdParser.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct XRPAssetIdParser {
    public init() {}

    public func getCurrencyCodeAndIssuer(from assetId: String) throws -> (currencyCode: String, issuer: String) {
        let normalized = normalizeAssetId(assetId)
        let parts = normalized.split(separator: ".").map(String.init)

        guard parts.count == 2 else {
            throw XRPError.failedParseAssetId
        }

        return (parts.first!, parts[1])
    }

    public func normalizeAssetId(_ assetId: String) -> String {
        assetId.replacingOccurrences(of: "-", with: ".")
    }
}
