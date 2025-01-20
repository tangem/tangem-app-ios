//
//  AlephiumNetworkService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

class AlephiumNetworkService: MultiNetworkProvider {
    // MARK: - Protperties

    let providers: [AlephiumNetworkProvider]
    var currentProviderIndex: Int = 0

    private var blockchain: Blockchain

    // MARK: - Init

    init(providers: [AlephiumNetworkProvider], blockchain: Blockchain) {
        self.providers = providers
        self.blockchain = blockchain
    }
}
