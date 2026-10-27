//
//  CollectiblesBuybackTerms.swift
//  TangemCollectibles
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public struct CollectiblesBuybackTerms: Sendable {
    public let nftAddress: String
    public let minimumPayoutInBaseUnits: UInt64

    public init(nftAddress: String, minimumPayoutInBaseUnits: UInt64) {
        self.nftAddress = nftAddress
        self.minimumPayoutInBaseUnits = minimumPayoutInBaseUnits
    }
}
