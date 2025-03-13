//
//  MoralisNetworkParams.NFTAssetsBody.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension MoralisNetworkParams {
    struct NFTAssetsBody {
        let tokens: [Token]
        let normalizeMetadata: Bool?
        let mediaItems: Bool?
    }
}

// MARK: - Encodable protocol conformance

/// The explicit `Encodable` conformance with manual `snake_case` encoding is added here because some DTOs
/// have some fields with `camelCase` encoding, while the vast majority of other fields have `snake_case` encoding.
/// This is why we can't just use `JSONEncoder.KeyEncodingStrategy.convertToSnake`, because in that case `JSONEncoder`
/// converts even those fields that have coding keys with a `camelCase`-like raw value to the `snake_case` encoding.
extension MoralisNetworkParams.NFTAssetsBody: Encodable {
    private enum CodingKeys: String, CodingKey {
        case tokens
        /// - Warning: must be `camelCase` encoded.
        case normalizeMetadata
        case mediaItems = "media_items"
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(tokens, forKey: CodingKeys.tokens)
        try container.encodeIfPresent(normalizeMetadata, forKey: CodingKeys.normalizeMetadata)
        try container.encodeIfPresent(mediaItems, forKey: CodingKeys.mediaItems)
    }
}

// MARK: - Nested DTOs

extension MoralisNetworkParams.NFTAssetsBody {
    struct Token {
        let tokenAddress: String
        let tokenId: String
    }
}

// MARK: - Encodable protocol conformance

/// The explicit `Encodable` conformance with manual `snake_case` encoding is added here because some DTOs
/// have some fields with `camelCase` encoding, while the vast majority of other fields have `snake_case` encoding.
/// This is why we can't just use `JSONEncoder.KeyEncodingStrategy.convertToSnake`, because in that case `JSONEncoder`
/// converts even those fields that have coding keys with a `camelCase`-like raw value to the `snake_case` encoding.
extension MoralisNetworkParams.NFTAssetsBody.Token: Encodable {
    private enum CodingKeys: String, CodingKey {
        case tokenAddress = "token_address"
        case tokenId = "token_id"
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(tokenAddress, forKey: CodingKeys.tokenAddress)
        try container.encode(tokenId, forKey: CodingKeys.tokenId)
    }
}
