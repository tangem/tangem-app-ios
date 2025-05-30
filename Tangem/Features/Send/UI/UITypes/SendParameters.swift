//
//  SendParameters.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemNFT

struct SendParameters {
    typealias NonFungibleTokenParameters = (asset: NFTAsset, collection: NFTCollection)

    let nonFungibleTokenParameters: NonFungibleTokenParameters?

    init(nonFungibleTokenParameters: NonFungibleTokenParameters? = nil) {
        self.nonFungibleTokenParameters = nonFungibleTokenParameters
    }
}
