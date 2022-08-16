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
    func append(_ entries: [StorageEntry], for cardId: String)

    func remove(_ blockchainNetworks: [BlockchainNetwork], for cardId: String)
    func remove(_ tokens: [Token], blockchainNetwork: BlockchainNetwork, for cardId: String)

    func removeAll(for cardId: String)
    func getItems(for cardId: String) -> [StorageEntry]

    func updateSubscriber(_ subscriber: TokenItemsRepositoryChanges)
}

protocol TokenItemsRepositoryChanges: AnyObject {
    func repositoryDidUpdates(entries: [StorageEntry])
}

extension TokenItemsRepository {
    func append(_ blockchains: [Blockchain], for cardId: String, style: DerivationStyle) {
        let networks = blockchains.map {
            BlockchainNetwork($0, derivationPath: $0.derivationPath(for: style))
        }

        append(networks, for: cardId)
    }

    func append(_ blockchainNetworks: [BlockchainNetwork], for cardId: String) {
        let entity = blockchainNetworks.map { StorageEntry(blockchainNetwork: $0, tokens: []) }
        append(entity, for: cardId)
    }

    func append(_ tokens: [Token], blockchainNetwork: BlockchainNetwork, for cardId: String) {
        let entity = StorageEntry(blockchainNetwork: blockchainNetwork, tokens: tokens)
        append([entity], for: cardId)
    }

    func remove(_ blockchainNetwork: BlockchainNetwork, for cardId: String) {
        remove([blockchainNetwork], for: cardId)
    }

    func remove(_ token: Token, blockchainNetwork: BlockchainNetwork, for cardId: String) {
        remove([token], blockchainNetwork: blockchainNetwork, for: cardId)
    }
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

