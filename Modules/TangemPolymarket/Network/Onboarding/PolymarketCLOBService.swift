//
//  PolymarketCLOBService.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public protocol PolymarketCLOBService {
    func createCredentials(authHeaders: PolymarketCLOBAuthHeaders) async throws -> PolymarketL2Credentials

    func deriveCredentials(authHeaders: PolymarketCLOBAuthHeaders) async throws -> PolymarketL2Credentials

    func updateBalanceAllowance(authHeaders: PolymarketCLOBAuthHeaders) async throws -> PolymarketBalanceAllowance

    func balanceAllowance(authHeaders: PolymarketCLOBAuthHeaders) async throws -> PolymarketBalanceAllowance
}
