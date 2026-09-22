//
//  PolymarketMapper+Withdraw.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - The backend's record of a withdrawal

extension PolymarketMapper {
    func mapWithdrawRecord(_ response: PolymarketDTO.WithdrawRecordResponse) -> PolymarketWithdrawRecord {
        PolymarketWithdrawRecord(
            transactionId: response.transactionId,
            state: response.state,
            transactionHash: response.transactionHash
        )
    }
}
