//
//  PolymarketDTO+Redeem.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension PolymarketDTO {
    struct RedeemCallResponse: Decodable {
        let target: String
        let value: String
        let data: String
    }

    struct RedeemRecordResponse: Decodable {
        let transactionId: String
        let state: PolymarketRedeemState
        let transactionHash: String?
    }
}
