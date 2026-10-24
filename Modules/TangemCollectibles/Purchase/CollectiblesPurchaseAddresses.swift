//
//  CollectiblesPurchaseAddresses.swift
//  TangemCollectibles
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public struct CollectiblesPurchaseAddresses: Equatable, Sendable {
    public let payer: String
    public let prizeRecipient: String

    public init(payer: String, prizeRecipient: String) {
        self.payer = payer
        self.prizeRecipient = prizeRecipient
    }
}
