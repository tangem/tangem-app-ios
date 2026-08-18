//
//  PolymarketRelayerService.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public protocol PolymarketRelayerService {
    func walletNonce(ownerAddress: String) async throws -> String
}
