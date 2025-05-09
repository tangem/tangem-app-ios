//
//  CommonNFTTokenIconInfoProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI
import TangemNFT

struct CommonNFTTokenIconInfoProvider: NFTTokenIconInfoProvider {
    private let builder = TokenIconInfoBuilder()

    func tokenIconInfo(for nftChain: NFTChain, isCustom: Bool) -> TokenIconInfo {
        // [REDACTED_TODO_COMMENT]
        // The dummy hardcoded `version` is used here since it has no effect on the icon generation in `TokenIconInfoBuilder`
        let blockchain = NFTChainConverter.convert(nftChain, version: .v2)
        return builder.build(for: .coin, in: blockchain, isCustom: isCustom)
    }
}
