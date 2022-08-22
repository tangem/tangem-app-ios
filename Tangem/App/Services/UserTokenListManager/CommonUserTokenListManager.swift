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
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService


    /// I use `var` because the repository will be updated after migration
    private var tokenItemsRepository: TokenItemsRepository

    private let userWalletId: String
    private let cardId: String

    private var loadTokensCancellable: AnyCancellable?
    private var saveTokensCancellable: AnyCancellable?

    init(userWalletId: String, cardId: String) {
        self.userWalletId = userWalletId
        self.cardId = cardId

        tokenItemsRepository = CommonTokenItemsRepository(key: cardId)
    }
}

// MARK: - UserTokenListManager

extension CommonUserTokenListManager: UserTokenListManager {
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

    func saveTokenListInRepository(entries: [StorageEntry]) {
        let tokens = mapToTokens(entries: entries)
        let list = UserTokenList(tokens: tokens)

        saveTokensCancellable = tangemApiService.saveTokens(key: userWalletId, list: list).sink()
    }
}

// MARK: - TokenItemsRepositoryChanges

extension CommonUserTokenListManager: TokenItemsRepositoryChanges {
    func repositoryDidUpdates(entries: [StorageEntry]) {
        let tokens = mapToTokens(entries: entries)
        let list = UserTokenList(tokens: tokens)

        saveTokensCancellable = tangemApiService.saveTokens(key: userWalletId, list: list).sink()
    }
}

// MARK: - Private

private extension CommonUserTokenListManager {
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
                saveTokenListInRepository(list: list)
                result(.success(list))
            }
    }

    func migrateAndUpdateTokensInBackend(result: @escaping (Result<UserTokenList, Error>) -> Void) {
        let entries = tokenItemsRepository.getItems()
        tokenItemsRepository.removeAll()

        // Recreate the repository for new key
        tokenItemsRepository = CommonTokenItemsRepository(key: userWalletId)
        tokenItemsRepository.append(entries)

        let tokens = mapToTokens(entries: entries)
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

    func saveTokenListInRepository(list: UserTokenList) {
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

        tokenItemsRepository.append(entries)
    }

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
}
