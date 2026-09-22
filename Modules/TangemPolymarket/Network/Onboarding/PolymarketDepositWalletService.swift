//
//  PolymarketDepositWalletService.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public protocol PolymarketDepositWalletService {
    func depositWalletState(ownerAddress: String?) async throws(PolymarketWalletError) -> PolymarketDepositWallet

    func deployWallet(
        ownerAddress: String,
        depositWalletAddress: String
    ) async throws(PolymarketWalletError) -> PolymarketDepositWalletStatus

    func submitApprovals(_ batch: PolymarketRelayedBatch) async throws(PolymarketWalletError) -> PolymarketDepositWalletStatus
}
