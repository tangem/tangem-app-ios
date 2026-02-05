//
//  CommonNFTCacheDelegate.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemNFT

/// We may run into a situation where we need to filter locally cached NFT collections based on
/// whether their wallet model exists or not. This delegate is used to determine if a collection
/// should be retrieved from the cache or filtered out.
/// This only applies to locally cached collections, since remotely fetched collections are always updated
/// based on the list of wallet models received on the emit of `walletModelsManager.walletModelsPublisher`.
final class CommonNFTCacheDelegate: NFTCacheDelegate {
    private let provideWalletModels: () -> [any WalletModel]

    init(provideWalletModels: @escaping () -> [any WalletModel]) {
        self.provideWalletModels = provideWalletModels
    }

    func cache(_ cache: NFTCache, shouldRetrieveCollection collection: NFTCollection) -> Bool {
        return NFTWalletModelFinder.findWalletModel(for: collection.id, in: provideWalletModels()) != nil
    }
}
