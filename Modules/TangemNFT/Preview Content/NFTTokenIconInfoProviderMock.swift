//
//  NFTTokenIconInfoProviderMock.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI
import TangemAssets

struct NFTTokenIconInfoProviderMock: NFTTokenIconInfoProvider {
    func tokenIconInfo(for nftChain: NFTChain, isCustom: Bool) -> TokenIconInfo {
        return TokenIconInfo(
            name: "Solana",
            blockchainIconAsset: Tokens.solana,
            imageURL: nil,
            isCustom: isCustom,
            customTokenColor: nil
        )
    }
}
