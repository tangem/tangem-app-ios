//
//  CollectiblesBuybackStatus.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum CollectiblesBuybackStatus: Equatable {
    case created
    case waitingTxHash
    case buybackTxSent
    case confirming
    case confirmed
    case expired
    case unknown(String)
}
