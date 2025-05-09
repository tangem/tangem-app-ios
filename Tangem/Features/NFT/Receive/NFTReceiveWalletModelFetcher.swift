//
//  NFTReceiveWalletModelFetcher.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemNFT

final class NFTReceiveWalletModelFetcher {
    private let walletModelsManager: WalletModelsManager

    init(
        walletModelsManager: WalletModelsManager
    ) {
        self.walletModelsManager = walletModelsManager
    }

    func fetch(for nftChainItem: NFTChainItem) -> (any WalletModel)? {
        return walletModelsManager
            .walletModels
            .first { AnyHashable($0.id.id) == nftChainItem.underlyingIdentifier }
    }
}
