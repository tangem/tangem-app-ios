//
//  CommonUserTokenListManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemSdk

class CommonUserTokenListManager {
    @Injected(\.tangemSdkProvider) private var tangemSdkProvider: TangemSdkProviding
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService
    @Injected(\.scannedCardsRepository) var scannedCardsRepository: ScannedCardsRepository

    private let tokenItemsRepository: TokenItemsRepository
    private let cardInfo: CardInfo
    private let config: UserWalletConfig

    private var loadTokensCancellable: AnyCancellable?
    private var saveTokensCancellable: AnyCancellable?

    private var card: Card { cardInfo.card }
    private var cardId: String { card.cardId }
    private var userWalletId: String { card.userWalletId }
    private var derivedKeys: [Data: [DerivationPath: ExtendedPublicKey]] { cardInfo.derivedKeys }

    init(config: UserWalletConfig, cardInfo: CardInfo) {
        self.config = config
        self.cardInfo = cardInfo

        tokenItemsRepository = CommonTokenItemsRepository(key: cardInfo.card.userWalletId)
    }
}

// MARK: - UserTokenListManager

extension CommonUserTokenListManager: UserTokenListManager {
    func append(entries: [StorageEntry], result: @escaping (Result<Void, Error>) -> Void) {
        tokenItemsRepository.append(entries)
        updateTokensOnServer(result: result)
    }

    func remove(blockchain: BlockchainNetwork, result: @escaping (Result<Void, Error>) -> Void) {
        tokenItemsRepository.remove([blockchain])
        updateTokensOnServer(result: result)
    }

    func remove(tokens: [BlockchainSdk.Token], in blockchain: BlockchainNetwork, result: @escaping (Result<Void, Error>) -> Void) {
        tokenItemsRepository.remove(tokens, blockchainNetwork: blockchain)
        updateTokensOnServer(result: result)
    }

    func syncGetEntriesFromRepository() -> [StorageEntry] {
        tokenItemsRepository.getItems()
    }

    func clearRepository(result: @escaping (Result<Void, Error>) -> Void) {
        tokenItemsRepository.removeAll()
        updateTokensOnServer(result: result)
    }

    func loadAndSaveUserTokenList() -> AnyPublisher<UserTokenList, Error> {
        Future<UserTokenList, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(CommonError.masterReleased))
                return
            }

            self.loadUserTokenList { result in
                switch result {
                case let .success(list):
                    promise(.success(list))
                case let .failure(error):
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension CommonUserTokenListManager {

    // MARK: - Requests

    func loadUserTokenList(result: @escaping (Result<UserTokenList, Error>) -> Void) {
        self.loadTokensCancellable = tangemApiService
            .loadTokens(key: userWalletId)
            .sink { [unowned self] completion in
                guard case let .failure(error) = completion else { return }

                if error.code == .notFound {
                    migrateAndUpdateTokensInBackend(result: result)
                } else {
                    result(.failure(error as Error))
                }
            } receiveValue: { [unowned self] list in
                tokenItemsRepository.append(mapToEntries(list: list))
                result(.success(list))
            }
    }

    func updateTokensOnServer(result: @escaping (Result<Void, Error>) -> Void) {
        let entries = tokenItemsRepository.getItems()
        let tokens = mapToTokens(entries: entries)
        let list = UserTokenList(tokens: tokens)

        saveTokensCancellable = tangemApiService
            .saveTokens(key: userWalletId, list: list)
            .receiveCompletion { completion in
                switch completion {
                case .finished:
                    result(.success(()))
                case let .failure(error):
                    result(.failure(error))
                }
            }
    }

    // MARK: - Migration

    func migrateAndUpdateTokensInBackend(result: @escaping (Result<UserTokenList, Error>) -> Void) {
        let oldRepository = CommonTokenItemsRepository(key: cardId)
        let oldEntries = CommonTokenItemsRepository(key: cardId).getItems()
        oldRepository.removeAll()

        // Save a old entries in new repository
        tokenItemsRepository.append(oldEntries)
        AppSettings.shared.migratedTokenRepository = true

        let tokens = mapToTokens(entries: oldEntries)
        let list = UserTokenList(tokens: tokens)

        saveTokensCancellable = tangemApiService.saveTokens(key: userWalletId, list: list)
            .receiveCompletion { completion in
                switch completion {
                case let .failure(error):
                    result(.failure(error))
                case .finished:
                    result(.success(list))
                }
            }
    }

    // MARK: - Derivation

    func deriveIfNeeded(entries: [StorageEntry], completion: @escaping (Result<Void, Error>) -> Void) {
        guard config.hasFeature(.hdWallets) else {
            completion(.success(()))
            return
        }

        let newDerivationPaths: [Data: [DerivationPath]] = entries.reduce(into: [:]) { result, entry in
            if let path = entry.blockchainNetwork.derivationPath,
               let publicKey = card.wallets.first(where: { $0.curve == entry.blockchainNetwork.blockchain.curve })?.publicKey,
               derivedKeys[publicKey]?[path] == nil {
                result[publicKey, default: []].append(path)
            }
        }

        if newDerivationPaths.isEmpty {
            completion(.success(()))
            return
        }

        deriveKeys(derivationPaths: newDerivationPaths, completion: completion)
    }

    func deriveKeys(derivationPaths: [Data: [DerivationPath]], completion: @escaping (Result<Void, Error>) -> Void) {
        let task = DeriveMultipleWalletPublicKeysTask(derivationPaths)
        tangemSdkProvider.sdk.startSession(with: task, cardId: cardId) { [weak self, card] result in
            switch result {
            case .success(let newDerivations):
                self?.updateDerivations(with: newDerivations)
                completion(.success(()))
            case .failure(let error):
                Analytics.logCardSdkError(error, for: .purgeWallet, card: card)
                completion(.failure(error))
            }
        }
    }

    func updateDerivations(with newDerivations: [Data: [DerivationPath: ExtendedPublicKey]]) {
        var cardInfo = self.cardInfo

        for newKey in newDerivations {
            for newDerivation in newKey.value {
                cardInfo.derivedKeys[newKey.key, default: [:]][newDerivation.key] = newDerivation.value
            }
        }

        scannedCardsRepository.add(cardInfo)
    }

    // MARK: - Mapping

    func mapToTokens(entries: [StorageEntry]) -> [UserTokenList.Token] {
        entries.reduce(into: []) { result, entry in
            let blockchain = entry.blockchainNetwork.blockchain
            result += [UserTokenList.Token(
                id: blockchain.id,
                networkId: blockchain.networkId,
                name: blockchain.displayName,
                symbol: blockchain.currencySymbol,
                decimals: blockchain.decimalCount,
                derivationPath: blockchain.derivationPath()?.rawPath,
                contractAddress: nil
            )]

            result += entry.tokens.map { token in
                UserTokenList.Token(
                    id: token.id,
                    networkId: blockchain.networkId,
                    name: token.name,
                    symbol: token.symbol,
                    decimals: token.decimalCount,
                    derivationPath: blockchain.derivationPath()?.rawPath,
                    contractAddress: token.contractAddress
                )
            }
        }
    }

    func mapToEntries(list: UserTokenList) -> [StorageEntry] {
        let networks = Dictionary(grouping: list.tokens, by: { $0.networkId })
        let entries = networks.compactMap { networkId, tokens -> StorageEntry? in
            guard let blockchain = Blockchain(from: networkId) else {
                assertionFailure("Blockchain for networkId \(networkId) not found)")
                return nil
            }

            let derivationRawValue = tokens.first { $0.derivationPath != nil }?.derivationPath
            print("derivationRawValue", derivationRawValue as Any)

            let tokens = tokens.compactMap { token -> BlockchainSdk.Token? in
                guard let contractAddress = token.contractAddress else {
                    return nil
                }

                return Token(
                    name: token.name,
                    symbol: token.symbol,
                    contractAddress: contractAddress,
                    decimalCount: token.decimals,
                    id: token.id
                )
            }

            let derivationPath = try? DerivationPath(rawPath: derivationRawValue ?? "")
            let blockchainNetwork = BlockchainNetwork(blockchain, derivationPath: derivationPath)
            return StorageEntry(
                blockchainNetwork: blockchainNetwork,
                tokens: tokens
            )
        }

        return entries
    }
}
