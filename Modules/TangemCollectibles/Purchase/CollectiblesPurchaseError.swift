//
//  CollectiblesPurchaseError.swift
//  TangemCollectibles
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public enum CollectiblesPurchaseError: Error {
    case transactionExpired
    case sendOutcomeUnknown
    case rejected(any Error)
}
