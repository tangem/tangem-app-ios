//
//  NFTCacheDelegate.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public protocol NFTCacheDelegate: AnyObject {
    func cache(_ cache: NFTCache, shouldRetrieveCollection collection: NFTCollection) -> Bool
}
