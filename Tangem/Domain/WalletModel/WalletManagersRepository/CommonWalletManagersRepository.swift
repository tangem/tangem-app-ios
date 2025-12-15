//
//  CommonWalletManagersRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

class CommonWalletManagersRepository {
    // MARK: - Dependencies

    @Injected(\.apiListProvider) private var apiListProvider: APIListProvider

    private let keysProvider: KeysProvider
    private let userTokensManager: UserTokensManager
    private let walletManagerFactory: AnyWalletManagerFactory

    /// We need to keep optional dictionary to track state when wallet managers dictionary wasn't able to initialize
    /// This state can happen while app awaiting API list from server, because Wallet managers can't be created without this info
    /// Nil state is not the same as an empty state, because user can remove all tokens from main and the dictionary will be empty
    private var walletManagers = CurrentValueSubject<[BlockchainNetwork: WalletManager]?, Never>(nil)
    private var bag = Set<AnyCancellable>()

    init(
        keysProvider: KeysProvider,
        userTokensManager: UserTokensManager,
        walletManagerFactory: AnyWalletManagerFactory
    ) {
        self.keysProvider = keysProvider
        self.userTokensManager = userTokensManager
        self.walletManagerFactory = walletManagerFactory
        bind()
    }

    private func bind() {
        Publishers.CombineLatest3(
            userTokensManager.userTokensPublisher,
            keysProvider.keysPublisher,
            apiListProvider.apiListPublisher
        )
        .sink { [weak self] entries, keys, apiList in
            self?.update(with: entries, keys, apiList: apiList)
        }
        .store(in: &bag)
    }

    private func update(with entries: [TokenItem], _ keys: [KeyInfo], apiList: APIList) {
        var managers = walletManagers.value ?? [:]
        var hasUpdates = false

        let gropedByNetwork = Dictionary(grouping: entries, by: { $0.blockchainNetwork })

        for (blockchainNetwork, items) in gropedByNetwork {
            let entryTokens = items.compactMap(\.token)

            if let existingWalletManager = walletManagers.value?[blockchainNetwork] {
                let tokensToRemove = Set(existingWalletManager.cardTokens).subtracting(entryTokens)
                for tokenToRemove in tokensToRemove {
                    existingWalletManager.removeToken(tokenToRemove)
                    hasUpdates = true
                }

                let tokensToAdd = Set(entryTokens).subtracting(existingWalletManager.cardTokens)
                if !tokensToAdd.isEmpty {
                    existingWalletManager.addTokens(Array(tokensToAdd))
                    // We need to reset lastUpdateTime to be able to load token info, if tokens added one by one sequentially.
                    // Otherwise balances on main will be displayed as dashes
                    existingWalletManager.setNeedsUpdate()
                    hasUpdates = true
                }

            } else if let newWalletManager = makeWalletManager(
                blockchainNetwork: blockchainNetwork,
                tokens: entryTokens,
                keys: keys,
                apiList: apiList
            ) {
                managers[blockchainNetwork] = newWalletManager
                hasUpdates = true
            }
        }

        let actualNetworks = Set(entries.map { $0.blockchainNetwork })
        let currentNetworks = Set(managers.keys)
        let networksToDelete = currentNetworks.subtracting(actualNetworks)

        if !networksToDelete.isEmpty {
            networksToDelete.forEach {
                managers[$0] = nil
            }
            hasUpdates = true
        }

        if walletManagers.value == nil {
            // Emit initial list. Case with first card scan without derivations
            hasUpdates = true
        }

        if hasUpdates {
            walletManagers.send(managers)
        }
    }

    private func makeWalletManager(blockchainNetwork: BlockchainNetwork, tokens: [Token], keys: [KeyInfo], apiList: APIList) -> WalletManager? {
        do {
            return try walletManagerFactory.makeWalletManager(blockchainNetwork: blockchainNetwork, tokens: tokens, keys: keys, apiList: apiList)
        } catch AnyWalletManagerFactoryError.noDerivation {
            AppLogger.warning("‼️ No derivation for \(blockchainNetwork.blockchain.displayName)")
        } catch {
            AppLogger.error("‼️ Failed to create \(blockchainNetwork.blockchain.displayName)", error: error)
        }

        return nil
    }
}

extension CommonWalletManagersRepository: WalletManagersRepository {
    var walletManagersPublisher: AnyPublisher<[BlockchainNetwork: any WalletManager], Never> {
        walletManagers
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
}
