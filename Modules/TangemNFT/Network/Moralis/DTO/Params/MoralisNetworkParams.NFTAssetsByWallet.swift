//
//  MoralisNetworkParams.NFTAssetsByWallet.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension MoralisNetworkParams {
    struct NFTAssetsByWallet {
        let chain: NFTChain?
        let format: Format?
        let limit: Int?
        let cursor: String?
        let excludeSpam: Bool?
        let tokenAddresses: [String]?
        let normalizeMetadata: Bool?
        let mediaItems: Bool?
        let includePrices: Bool?
    }
}

// MARK: - Encodable protocol conformance

/// The explicit `Encodable` conformance with manual `snake_case` encoding is added here because some DTOs
/// have some fields with `camelCase` encoding, while the vast majority of other fields have `snake_case` encoding.
/// This is why we can't just use `JSONEncoder.KeyEncodingStrategy.convertToSnake`, because in that case `JSONEncoder`
/// converts even those fields that have coding keys with a `camelCase`-like raw value to the `snake_case` encoding.
extension MoralisNetworkParams.NFTAssetsByWallet: Encodable {
    private enum CodingKeys: String, CodingKey {
        case chain
        case format
        case limit
        case cursor
        case excludeSpam = "exclude_spam"
        case tokenAddresses = "token_addresses"
        /// - Warning: must be `camelCase` encoded.
        case normalizeMetadata
        case mediaItems = "media_items"
        case includePrices = "include_prices"
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encodeIfPresent(chain, forKey: CodingKeys.chain)
        try container.encodeIfPresent(format, forKey: CodingKeys.format)
        try container.encodeIfPresent(limit, forKey: CodingKeys.limit)
        try container.encodeIfPresent(cursor, forKey: CodingKeys.cursor)
        try container.encodeIfPresent(excludeSpam, forKey: CodingKeys.excludeSpam)
        try container.encodeIfPresent(tokenAddresses, forKey: CodingKeys.tokenAddresses)
        try container.encodeIfPresent(normalizeMetadata, forKey: CodingKeys.normalizeMetadata)
        try container.encodeIfPresent(mediaItems, forKey: CodingKeys.mediaItems)
        try container.encodeIfPresent(includePrices, forKey: CodingKeys.includePrices)
    }
}

// MARK: - Nested DTOs

extension MoralisNetworkParams.NFTAssetsByWallet {
    enum Format: Encodable {
        case decimal
        case hex
    }
}
