//
//  CollectiblesConfigInfo.swift
//  TangemCollectibles
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import Foundation

/// Domain representation of the program's singleton `Config` account.
public struct CollectiblesConfigInfo: Hashable, Sendable {
    /// Mint the program settles in — a test token on devnet, so it can never be a constant.
    public let usdcMint: Data

    /// Bounds for a spin's `fee_amount`, in basis points of the amount the backend picks it from.
    public let minFeeBps: UInt16
    public let maxFeeBps: UInt16

    public init(usdcMint: Data, minFeeBps: UInt16, maxFeeBps: UInt16) {
        self.usdcMint = usdcMint
        self.minFeeBps = minFeeBps
        self.maxFeeBps = maxFeeBps
    }
}

/// Chain read of the program's config. A missing or foreign account throws: it means the program is not
/// where the app thinks it is, which is nothing like a wallet simply not being onboarded.
public protocol CollectiblesConfigReader: AnyObject {
    func configInfo() async throws -> CollectiblesConfigInfo
}
