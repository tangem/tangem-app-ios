//
//  MoralisNetworkParams.NFTCollectionsByWallet.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension MoralisNetworkParams {
    struct NFTCollectionsByWallet: Encodable {
        let chain: NFTChain?
        let limit: Int?
        let cursor: String?
        let tokenCounts: Bool?
        let excludeSpam: Bool?
    }
}

// MARK: - Encodable protocol conformance

/// The explicit `Encodable` conformance with manual `snake_case` encoding is added here because some DTOs
/// have some fields with `camelCase` encoding, while the vast majority of other fields have `snake_case` encoding.
/// This is why we can't just use `JSONEncoder.KeyEncodingStrategy.convertToSnake`, because in that case `JSONEncoder`
/// converts even those fields that have coding keys with a `camelCase`-like raw value to the `snake_case` encoding.
extension MoralisNetworkParams.NFTCollectionsByWallet {
    private enum CodingKeys: String, CodingKey {
        case chain
        case limit
        case cursor
        case tokenCounts = "token_counts"
        case excludeSpam = "exclude_spam"
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encodeIfPresent(chain, forKey: CodingKeys.chain)
        try container.encodeIfPresent(limit, forKey: CodingKeys.limit)
        try container.encodeIfPresent(cursor, forKey: CodingKeys.cursor)
        try container.encodeIfPresent(tokenCounts, forKey: CodingKeys.tokenCounts)
        try container.encodeIfPresent(excludeSpam, forKey: CodingKeys.excludeSpam)
    }
}
