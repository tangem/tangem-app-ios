//
//  PolymarketDTO+Withdraw.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension PolymarketDTO {
    struct BridgeWithdrawRequest: Encodable {
        let address: String
        let toChainId: String
        let toTokenAddress: String
        let recipientAddr: String
    }

    struct WithdrawRecordResponse: Decodable {
        let transactionId: String
        let state: PolymarketWithdrawState
        let transactionHash: String?
    }
}
