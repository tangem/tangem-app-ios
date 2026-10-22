//
//  MoralisSolanaNetworkParams.NFTsByWalletEarlyAccess.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

extension MoralisSolanaNetworkParams {
    struct NFTsByWalletEarlyAccess: Encodable {
        let chains: String
        let tokenStandards: String
        let limit: Int
        let cursor: String?
        let excludeSpam: Bool
        let includeMetadata: Bool
        let includeMedia: Bool
    }
}
