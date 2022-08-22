//
//  TokenItemsRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol TokenItemsRepository {
    func append(_ blockchains: [Blockchain], for cardId: String, style: DerivationStyle)
    func append(_ entries: [StorageEntry], for cardId: String)
    func append(_ blockchainNetworks: [BlockchainNetwork], for cardId: String)
    func append(_ tokens: [Token], blockchainNetwork: BlockchainNetwork, for cardId: String)

    func remove(_ blockchainNetwork: BlockchainNetwork, for cardId: String)
    func remove(_ blockchainNetworks: [BlockchainNetwork], for cardId: String)
    func remove(_ token: Token, blockchainNetwork: BlockchainNetwork, for cardId: String)
    func remove(_ tokens: [Token], blockchainNetwork: BlockchainNetwork, for cardId: String)
    func removeAll(for cardId: String)

    func getItems(for cardId: String) -> [StorageEntry]
}

private struct TokenItemsRepositoryKey: InjectionKey {
    static var currentValue: TokenItemsRepository = CommonTokenItemsRepository()
}

extension InjectedValues {
    var tokenItemsRepository: TokenItemsRepository {
        get { Self[TokenItemsRepositoryKey.self] }
        set { Self[TokenItemsRepositoryKey.self] = newValue }
    }
}

