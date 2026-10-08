//
//  CampaignEligibleTokensProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

enum EligibleTokenMatcher {
    private struct Key: Hashable {
        let networkId: String
        let contractAddress: String
    }

    static func make(from tokens: [CampaignEligibleToken]) -> (TokenItem) -> Bool {
        let keys = Set(tokens.map(key(for:)))

        return { tokenItem in
            guard let contractAddress = tokenItem.contractAddress else {
                return false
            }

            return keys.contains(Key(networkId: tokenItem.networkId, contractAddress: contractAddress.lowercased()))
        }
    }

    static func token(matching tokenItem: TokenItem, in tokens: [CampaignEligibleToken]) -> CampaignEligibleToken? {
        guard let contractAddress = tokenItem.contractAddress else {
            return nil
        }

        return token(networkId: tokenItem.networkId, contractAddress: contractAddress, in: tokens)
    }

    static func token(networkId: String, contractAddress: String, in tokens: [CampaignEligibleToken]) -> CampaignEligibleToken? {
        let key = Key(networkId: networkId, contractAddress: contractAddress.lowercased())
        return tokens.first { Self.key(for: $0) == key }
    }

    private static func key(for token: CampaignEligibleToken) -> Key {
        Key(networkId: token.networkId, contractAddress: token.tokenAddress.lowercased())
    }
}
