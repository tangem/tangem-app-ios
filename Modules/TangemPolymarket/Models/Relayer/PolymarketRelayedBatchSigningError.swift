//
//  PolymarketRelayedBatchSigningError.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public enum PolymarketRelayedBatchSigningError: Error, Equatable {
    case invalidDepositWalletAddress
    case invalidNonce
    case invalidDeadline
}
