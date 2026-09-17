//
//  CollectiblesConfigInfo.swift
//  TangemCollectibles
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import Foundation

/// Domain representation of the program's singleton `Config` account. Only the mint is exposed so far;
/// the treasuries and the fee it also holds join when the spending pipeline needs them.
public struct CollectiblesConfigInfo: Hashable, Sendable {
    /// Mint the program settles in — a test token on devnet, so it can never be a constant.
    public let usdcMint: Data

    public init(usdcMint: Data) {
        self.usdcMint = usdcMint
    }
}

/// Chain read of the program's config. A missing or foreign account throws: it means the program is not
/// where the app thinks it is, which is nothing like a wallet simply not being onboarded.
public protocol CollectiblesConfigReader: AnyObject {
    func configInfo() async throws -> CollectiblesConfigInfo
}
