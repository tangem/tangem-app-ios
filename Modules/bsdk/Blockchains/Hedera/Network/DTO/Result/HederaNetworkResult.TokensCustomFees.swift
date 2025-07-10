//
//  HederaNetworkResult.TokensCustomFees.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension HederaNetworkResult {
    /// there are more fields available
    /// on the /tokens/<token_id> response, ignore for now
    struct TokenDetails: Decodable {
        let customFees: CustomFees
    }

    struct CustomFees: Decodable {
        let fixedFees: [CustomFixedFee]
        let fractionalFees: [CustomFractionalFee]

        struct CustomFixedFee: Decodable {
            let amount: Decimal?
            let denominatingTokenId: String?
        }

        struct CustomFractionalFee: Decodable {
            let denominatingTokenId: String?
        }
    }
}
