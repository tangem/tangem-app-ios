//
//  MoralisNetworkParams.NFTSalePrice.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension MoralisNetworkParams {
    struct NFTSalePrice: Encodable {
        let chain: NFTChain?
        let days: Int?
    }
}
