//
//  PolymarketDTO+RelayedBatch.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension PolymarketDTO {
    struct RelayedBatchRequest: Encodable {
        let ownerAddress: String
        let depositWalletAddress: String
        let nonce: String
        let deadline: String
        let calls: [RelayedCall]
        let signature: String

        init(batch: PolymarketRelayedBatch) {
            ownerAddress = batch.ownerAddress
            depositWalletAddress = batch.depositWalletAddress
            nonce = batch.nonce
            deadline = batch.deadline
            calls = batch.calls.map(RelayedCall.init)
            signature = batch.signature
        }
    }

    struct RelayedCall: Encodable {
        let target: String
        let value: String
        let data: String
    }
}

extension PolymarketDTO.RelayedCall {
    init(_ call: PolymarketRelayedBatch.Call) {
        self.init(target: call.target, value: call.value, data: call.data)
    }
}
