//
//  PolymarketWalletService.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public protocol PolymarketWalletService {
    func walletState(ownerAddress: String) async throws(PolymarketWalletError) -> PolymarketWalletState

    func deployWallet(
        ownerAddress: String,
        depositWalletAddress: String,
        walletId: String
    ) async throws(PolymarketWalletError) -> PolymarketWalletStatus

    func submitApprovals(_ batch: PolymarketApprovalsBatch) async throws(PolymarketWalletError) -> PolymarketWalletStatus
}
