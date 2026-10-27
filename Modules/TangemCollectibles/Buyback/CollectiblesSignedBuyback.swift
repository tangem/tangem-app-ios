//
//  CollectiblesSignedBuyback.swift
//  TangemCollectibles
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct CollectiblesSignedBuyback: Sendable {
    public let signature: String

    let serializedTransaction: Data
    let receivedAt: Date
}
