//
//  MoralisSolanaNetworkParams.NFTsByWallet.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

extension MoralisSolanaNetworkParams {
    struct NFTsByWallet: Encodable {
        let nftMetadata: Bool?
        let mediaItems: Bool?
        let excludeSpam: Bool?
    }
}
