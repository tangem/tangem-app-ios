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
    private let keysProvider: KeysProvider
    private let userTokenListManager: UserTokenListManager
    private let walletManagerFactory: AnyWalletManagerFactory

    private var walletManagers = CurrentValueSubject<[BlockchainNetwork: any WalletManager], Never>([:])
    private var bag = Set<AnyCancellable>()

    init(
        keysProvider: KeysProvider,
        userTokenListManager: UserTokenListManager,
        walletManagerFactory: AnyWalletManagerFactory
    ) {
        self.keysProvider = keysProvider
        self.userTokenListManager = userTokenListManager
        self.walletManagerFactory = walletManagerFactory
        bind()
    }

    private func bind() {
        userTokenListManager.userTokensPublisher
            .sink { [weak self] entries in
                self?.update(with: entries)
            }
            .store(in: &bag)
    }

    private func update(with entries: [StorageEntry]) {
        var managers = walletManagers.value
        var hasUpdates = false

        entries.forEach { entry in
            if let existingWalletManager = walletManagers.value[entry.blockchainNetwork] {

                let tokensToRemove = Set(existingWalletManager.cardTokens).subtracting(entry.tokens)
                for tokenToRemove in tokensToRemove {
                    existingWalletManager.removeToken(tokenToRemove)
                    hasUpdates = true
                }

                let tokensToAdd = Set(entry.tokens).subtracting(existingWalletManager.cardTokens)
                if !tokensToAdd.isEmpty {
                    existingWalletManager.addTokens(Array(tokensToAdd))
                    hasUpdates = true
                }

            } else if let newWalletManager = makeWalletManager(for: entry) {
                managers[entry.blockchainNetwork] = newWalletManager
                hasUpdates = true
            }
        }

        if hasUpdates {
            walletManagers.send(managers)
        }
    }

    private func makeWalletManager(for entry: StorageEntry) -> WalletManager? {
        do {
            return try walletManagerFactory.makeWalletManager(for: entry, keys: keysProvider.keys)
        }
        catch AnyWalletManagerFactoryError.noDerivation {
            AppLog.shared.debug("‼️ No derivation for \(entry.blockchainNetwork.blockchain.displayName)")
        } catch {
            AppLog.shared.debug("‼️ Failed to create \(entry.blockchainNetwork.blockchain.displayName)")
            AppLog.shared.error(error)
        }

        return nil
    }
}

extension CommonWalletManagersRepository: WalletManagersRepository {
    var walletManagersPublisher: AnyPublisher<[BlockchainNetwork: any WalletManager], Never> {
        walletManagers.eraseToAnyPublisher()
    }
}
