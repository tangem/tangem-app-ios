//
//  WCTransactionNetworkRowViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemUI
import TangemAssets

struct WCTransactionNetworkRowViewModel {
    let blockchainName: String
    let blockchainIcon: ImageType

    private let blockchain: Blockchain

    init(blockchain: Blockchain) {
        self.blockchain = blockchain
        blockchainName = blockchain.displayName
        blockchainIcon = NetworkImageProvider().provide(by: blockchain, filled: true)
    }
}
