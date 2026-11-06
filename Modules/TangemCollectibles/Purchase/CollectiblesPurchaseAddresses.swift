//
//  CollectiblesPurchaseAddresses.swift
//  TangemCollectibles
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public struct CollectiblesPurchaseAddresses: Equatable, Sendable {
    public let player: String
    public let prizeRecipient: String
    public let payoutRecipient: String

    public init(player: String, prizeRecipient: String, payoutRecipient: String) {
        self.player = player
        self.prizeRecipient = prizeRecipient
        self.payoutRecipient = payoutRecipient
    }
}
