//
//  WalletModelId.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct WalletModelId: Hashable, Identifiable {
    let id: String
    let tokenItem: TokenItem

    init(tokenItem: TokenItem) {
        self.tokenItem = tokenItem

        let network = tokenItem.networkId
        let contract = tokenItem.contractAddress?.nilIfEmpty ?? "coin"
        let path = tokenItem.blockchainNetwork.derivationPath?.rawPath.nilIfEmpty ?? "no_derivation"
        id = "\(network)_\(contract)_\(path)"
    }
}
