//
//  NFTCache+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemNFT
import TangemFoundation

extension NFTCache {
    /// Convenience initializer that creates a new NFTCache for a user wallet with a given identifier.
    convenience init(userWalletId: UserWalletId) {
        self.init(cacheFileName: .cachedNFTAssets(userWalletIdStringValue: userWalletId.stringValue))
    }
}
