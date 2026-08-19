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

    static func make(from tokens: [BannerPromotion.Response.Token]) -> (TokenItem) -> Bool {
        let keys = Set(tokens.map { Key(networkId: $0.networkId, contractAddress: $0.tokenAddress.lowercased()) })

        return { tokenItem in
            guard let contractAddress = tokenItem.contractAddress?.lowercased() else {
                return false
            }

            return keys.contains(Key(networkId: tokenItem.networkId, contractAddress: contractAddress))
        }
    }
}
