//
//  CommonUserTokensManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

struct CommonUserTokensManager {
    private let userTokenListManager: UserTokenListManager
    private let derivationStyle: DerivationStyle?
    private let derivationManager: DerivationManager?
    private weak var cardDerivableProvider: CardDerivableProvider?

    init(
        userTokenListManager: UserTokenListManager,
        derivationStyle: DerivationStyle?,
        derivationManager: DerivationManager?,
        cardDerivableProvider: CardDerivableProvider
    ) {
        self.userTokenListManager = userTokenListManager
        self.derivationStyle = derivationStyle
        self.derivationManager = derivationManager
        self.cardDerivableProvider = cardDerivableProvider
    }


    private func makeBlockchainNetwork(for blockchain: Blockchain, derivationPath: DerivationPath?) -> BlockchainNetwork {
        if let derivationPath = derivationPath {
            return BlockchainNetwork(blockchain, derivationPath: derivationPath)
        }

        if let derivationStyle {
            let derivationPath = blockchain.derivationPaths(for: derivationStyle)[.default]
            return BlockchainNetwork(blockchain, derivationPath: derivationPath)
        }

        return BlockchainNetwork(blockchain, derivationPath: nil)
    }

    private func deriveIfNeeded(completion: @escaping (Result<Void, TangemSdkError>) -> Void) {
        guard let derivationManager,
              let interactor = cardDerivableProvider?.cardDerivableInteractor else {
            completion(.success(()))
            return
        }

        derivationManager.deriveKeys(cardInteractor: interactor, completion: completion)
    }
}

extension CommonUserTokensManager: UserTokensManager {
    func contains(_ tokenItem: TokenItem, derivationPath: DerivationPath?) -> Bool {
        let blockchainNetwork = makeBlockchainNetwork(for: tokenItem.blockchain, derivationPath: derivationPath)
        let entry = StorageEntry(blockchainNetwork: blockchainNetwork, token: tokenItem.token)
        return userTokenListManager.contains(entry)
    }

    func add(_ tokenItem: TokenItem, derivationPath: DerivationPath?, completion: @escaping (Result<Void, TangemSdkError>) -> Void) {
        let blockchainNetwork = makeBlockchainNetwork(for: tokenItem.blockchain, derivationPath: derivationPath)
        let entry = StorageEntry(blockchainNetwork: blockchainNetwork, token: tokenItem.token)
        userTokenListManager.update(.append([entry]))
        deriveIfNeeded(completion: completion)
    }

    func remove(_ tokenItem: TokenItem, derivationPath: DerivationPath?) {
        let blockchainNetwork = makeBlockchainNetwork(for: tokenItem.blockchain, derivationPath: derivationPath)

        if let token = tokenItem.token {
            userTokenListManager.update(.removeToken(token, in: blockchainNetwork))
        } else {
            userTokenListManager.update(.removeBlockchain(blockchainNetwork))
        }
    }
}
