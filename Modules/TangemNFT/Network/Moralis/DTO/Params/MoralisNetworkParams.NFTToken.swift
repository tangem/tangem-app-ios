//
//  MoralisNetworkParams.NFTToken.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension MoralisNetworkParams {
    struct NFTToken: Encodable {
        let tokenAddress: String
        let tokenId: String
    }
}
