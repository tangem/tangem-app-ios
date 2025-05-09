//
//  NFTChainItem.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

/// Just a wrapper for the `NFTChain` domain model, enriched with some additional data.
public struct NFTChainItem: Hashable {
    public let nftChain: NFTChain
    public let isCustom: Bool
    public let displayName: String
    /// Opaque identifier, used only by external consumers and has no use within `TangemNFT` domain.
    public let underlyingIdentifier: AnyHashable?

    public init(nftChain: NFTChain, isCustom: Bool, displayName: String, underlyingIdentifier: AnyHashable?) {
        self.nftChain = nftChain
        self.isCustom = isCustom
        self.displayName = displayName
        self.underlyingIdentifier = underlyingIdentifier
    }
}
