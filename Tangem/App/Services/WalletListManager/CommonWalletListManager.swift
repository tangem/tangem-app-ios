//
//  CommonWalletListManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Combine

class CommonWalletListManager {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    private var config: UserWalletConfig
    private let userTokenListManager: UserTokenListManager

    /// Bool flag for migration custom token to token form our API
    private var migrated = false
    private var walletModels = CurrentValueSubject<[WalletModel], Never>([])
    private var entriesWithoutDerivation = CurrentValueSubject<[StorageEntry], Never>([])

    init(config: UserWalletConfig, userTokenListManager: UserTokenListManager) {
        self.config = config
        self.userTokenListManager = userTokenListManager
    }
}

// MARK: - WalletListManager

extension CommonWalletListManager: WalletListManager {
    func update(config: UserWalletConfig) {
        print("‼️ Updating WalletListManager with new config")
        self.config = config
    }

    func getWalletModels() -> [WalletModel] {
        walletModels.value
    }

    func subscribeWalletModels() -> AnyPublisher<[WalletModel], Never> {
        walletModels.dropFirst().eraseToAnyPublisher()
    }

    func getNonDerivationEntries() -> [StorageEntry] {
        entriesWithoutDerivation.value
    }

    func subscribeNonDerivationEntries() -> AnyPublisher<[StorageEntry], Never> {
        entriesWithoutDerivation.dropFirst().eraseToAnyPublisher()
    }

    func updateWalletModels() {
        print("‼️ Updating Wallet models")

        var walletModels = getWalletModels()
        let entries = userTokenListManager.syncGetEntriesFromRepository()
        log(entires: entries)

        // Update tokens
        entries.forEach { entry in
            if let walletModel = walletModels.first(where: { $0.blockchainNetwork == entry.blockchainNetwork }) {
                entry.tokens.forEach { token in
                    if !walletModel.getTokens().contains(token) {
                        walletModel.addTokens(entry.tokens)
                    }
                }

                walletModel.getTokens().forEach { token in
                    if !entry.tokens.contains(token) {
                        walletModel.removeToken(token)
                    }
                }
            }
        }

        var nonDeriveEntries: [StorageEntry] = []

        let walletModelsToAdd = entries
            .filter { entry in
                !walletModels.contains(where: { $0.blockchainNetwork == entry.blockchainNetwork })
            }
            .compactMap { entry in
                do {
                    return try config.makeWalletModel(for: entry)
                } catch {
                    print("‼️ Make WalletModel error catch \(error)")
                    nonDeriveEntries.append(entry)
                    return nil
                }
            }

        walletModels.removeAll(where: { walletModel in
            if !entries.contains(where: { $0.blockchainNetwork == walletModel.blockchainNetwork }) {
                print("‼️ WalletModel will be removed \(walletModel.blockchainNetwork.blockchain.displayName)")
                return true
            }

            return false
        })


        walletModels.append(contentsOf: walletModelsToAdd)
        log(walletModels: walletModels)

        entriesWithoutDerivation.send(nonDeriveEntries)
        self.walletModels.send(walletModels)
    }

    func reloadAllWalletModels() -> AnyPublisher<Void, Error> {
        guard !getWalletModels().isEmpty else {
            print("‼️ WalletModels is empty")
            return Empty().eraseToAnyPublisher()
        }

        return reloadAllWalletModelsPublisher()
    }

    func canManage(amountType: Amount.AmountType, blockchainNetwork: BlockchainNetwork) -> Bool {
        if let walletModel = getWalletModels().first(where: { $0.blockchainNetwork == blockchainNetwork }) {
            return walletModel.canRemove(amountType: amountType)
        }

        return true
    }

    func canRemove(amountType: Amount.AmountType, blockchainNetwork: BlockchainNetwork) -> Bool {
        if let walletModel = getWalletModels().first(where: { $0.blockchainNetwork == blockchainNetwork }) {
            return walletModel.canRemove(amountType: amountType)
        }

        return false
    }

    func removeToken(_ token: Token, blockchainNetwork: BlockchainNetwork) {
        getWalletModels().first(where: { $0.blockchainNetwork == blockchainNetwork })?.removeToken(token)
        updateWalletModels()
    }
}

private extension CommonWalletListManager {
    func reloadAllWalletModelsPublisher() -> AnyPublisher<Void, Error> {
        tryMigrateTokens()
            .tryMap { [weak self] _ ->  AnyPublisher<Void, Error> in
                guard let self = self else {
                    throw CommonError.masterReleased
                }

                return self.observeBalanceLoading()
            }
            .switchToLatest()
            .eraseToAnyPublisher()
    }

    func observeBalanceLoading() -> AnyPublisher<Void, Error> {
        let publishers = getWalletModels().map { $0.update() }
        return Publishers
            .MergeMany(publishers)
            .collect(publishers.count)
            .mapVoid()
            .eraseToAnyPublisher()
    }

    func tryMigrateTokens() -> AnyPublisher<Void, Never>  {
        if migrated {
            return .just
        }

        migrated = true

        let items = userTokenListManager.syncGetEntriesFromRepository()
        let itemsWithCustomTokens = items.filter { item in
            return item.tokens.contains(where: { $0.isCustom })
        }

        if itemsWithCustomTokens.isEmpty {
            return .just
        }

        let publishers: [AnyPublisher<Bool, Never>] = itemsWithCustomTokens.reduce(into: []) { result, item in
            result += item.tokens.filter { $0.isCustom }.map { token -> AnyPublisher<Bool, Never> in
                updateCustomToken(token: token, in: item.blockchainNetwork)
            }
        }

        return Publishers.MergeMany(publishers)
            .collect()
            .handleEvents(receiveOutput: { [weak self] migrationResults in
                if migrationResults.contains(true) {
                    self?.updateWalletModels()
                }
            })
            .mapVoid()
            .eraseToAnyPublisher()
    }

    func updateCustomToken(token: Token, in blockchainNetwork: BlockchainNetwork) -> AnyPublisher<Bool, Never> {
        let requestModel = CoinsListRequestModel(
            contractAddress: token.contractAddress,
            networkIds: [blockchainNetwork.blockchain.networkId]
        )

        return tangemApiService
            .loadCoins(requestModel: requestModel)
            .replaceError(with: [])
            .flatMap { [weak self] models -> AnyPublisher<Bool, Never> in
                guard let self = self,
                      let token = models.first?.items.compactMap({ $0.token }).first else {
                    return Just(false).eraseToAnyPublisher()
                }

                return Future<Bool, Never> { promise in
                    let entry = StorageEntry(blockchainNetwork: blockchainNetwork, token: token)
                    self.userTokenListManager.append(entries: [entry]) { result in
                        switch result {
                        case .success:
                            promise(.success(true))
                        case .failure:
                            promise(.success(false))
                        }
                    }
                }
                .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    func log(entires: [StorageEntry]) {
        let printList = entires.map { entry in
            var text = "blockchain: \(entry.blockchainNetwork.blockchain.displayName)"
            if !entry.tokens.isEmpty {
                text += " with tokens: \(entry.tokens.map { $0.name }.joined(separator: ", "))"
            }
            return text
        }

        print("✅ Actual List of StorageEntry [\(printList.joined(separator: ", "))]")
    }

    func log(walletModels: [WalletModel]) {
        let printList = walletModels.map { walletModel in
            var text = "blockchain: \(walletModel.blockchainNetwork.blockchain.displayName)"
            if !walletModel.getTokens().isEmpty {
                text += " with tokens: \(walletModel.getTokens().map { $0.name }.joined(separator: ", "))"
            }
            return text
        }

        print("✅ Actual List of WalletModels [\(printList.joined(separator: ", "))]")
    }
}
