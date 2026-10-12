//
//  PolymarketDepositSendingUnsupportedError.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum PolymarketDepositSendingUnsupportedError: LocalizedError {
    case sendingUnsupported

    var errorDescription: String? {
        "Nothing is ever sent from a Polymarket deposit address"
    }
}
