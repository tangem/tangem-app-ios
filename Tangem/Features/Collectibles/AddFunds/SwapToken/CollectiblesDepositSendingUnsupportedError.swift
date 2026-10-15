//
//  CollectiblesDepositSendingUnsupportedError.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum CollectiblesDepositSendingUnsupportedError: LocalizedError {
    case sendingUnsupported

    var errorDescription: String? {
        "Nothing is ever sent from a Packs account deposit address"
    }
}
