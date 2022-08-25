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

    private let config: UserWalletConfig
    private let cardInfo: CardInfo
    private let userTokenListManager: UserTokenListManager

    /// Bool flag for migration custom token to token form our API
    private var migrated = false
    private var walletModels = CurrentValueSubject<[WalletModel], Never>([])
    private var entriesRequriedDerivaton: [StorageEntry] = []

    init(config: UserWalletConfig, cardInfo: CardInfo, userTokenListManager: UserTokenListManager) {
        self.config = config
        self.cardInfo = cardInfo
        self.userTokenListManager = userTokenListManager
    }
}

// MARK: - WalletListManager

extension CommonWalletListManager: WalletListManager {
    func subscribeWalletModels() -> AnyPublisher<[WalletModel], Never> {
        walletModels.dropFirst().eraseToAnyPublisher()
    }

    func getWalletModels() -> [WalletModel] {
        walletModels.value
    }

    func updateWalletModels() {
        print("‼️ Updating Wallet models")

        guard !cardInfo.card.wallets.isEmpty else {
            print("‼️ Wallets in the card is empty")

            self.walletModels.send([])
            return
        }

        var walletModels = getWalletModels()
        let entries = userTokenListManager.syncGetEntriesFromRepository()

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

        let walletModelsToAdd = entries
            .filter { entry in
                !walletModels.contains(where: { $0.blockchainNetwork == entry.blockchainNetwork })
            }
            .compactMap { entry in
                do {
                    return try config.makeWalletModel(for: entry, derivedKeys: cardInfo.derivedKeys)
                } catch {
                    print("‼️ makeWalletModel error \(error)")
                    entriesRequriedDerivaton.append(entry)
                    return nil
                }
            }

        walletModels.removeAll(where: { walletModel in
            !entries.contains(where: { $0.blockchainNetwork == walletModel.blockchainNetwork })
        })

        walletModels.append(contentsOf: walletModelsToAdd)

        walletModels.forEach {
            print("⁉️ Update walletModel for \($0.blockchainNetwork.blockchain.displayName)")
        }

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

    func removeToken(_ token: BlockchainSdk.Token, blockchainNetwork: BlockchainNetwork) {
        getWalletModels().first(where: { $0.blockchainNetwork == blockchainNetwork })?.removeToken(token)
        updateWalletModels()
    }
}

private extension CommonWalletListManager {
    func makeAllWalletModels() -> [WalletModel] {
        let tokens = userTokenListManager.syncGetEntriesFromRepository()
        return tokens.compactMap {
            try? config.makeWalletModel(for: $0, derivedKeys: cardInfo.derivedKeys)
        }
    }

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
        Publishers
            .MergeMany(getWalletModels().map({ $0.update() }))
            .collect(getWalletModels().count)
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
}
