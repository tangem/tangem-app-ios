//
//  ReceiveFlow.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum ReceiveFlow {
    case nft
    case crypto
    /// Funding a Polymarket account: the address on screen belongs to Polymarket's bridge, not to the wallet.
    case polymarketDeposit
}
