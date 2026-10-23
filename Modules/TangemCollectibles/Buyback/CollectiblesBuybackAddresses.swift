//
//  CollectiblesBuybackAddresses.swift
//  TangemCollectibles
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public struct CollectiblesBuybackAddresses: Sendable {
    public let owner: String
    public let payoutRecipient: String

    public init(owner: String, payoutRecipient: String) {
        self.owner = owner
        self.payoutRecipient = payoutRecipient
    }
}
