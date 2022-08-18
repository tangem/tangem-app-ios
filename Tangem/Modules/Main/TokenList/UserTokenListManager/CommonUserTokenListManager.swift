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

class CommonUserTokenListManager {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService
    @Injected(\.tokenItemsRepository) private var tokenItemsRepository: TokenItemsRepository

    private let accountId: String
    private let cardId: String

    private var loadTokensCancellable: AnyCancellable?
    private var saveTokensCancellable: AnyCancellable?

    init(accountId: String, cardId: String) {
        self.accountId = accountId
        self.cardId = cardId

        tokenItemsRepository.setSubscriber(self)
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
}

// MARK: - TokenItemsRepositoryChanges

extension CommonUserTokenListManager: TokenItemsRepositoryChanges {
    func repositoryDidUpdates(entries: [StorageEntry]) {
        let tokens = mapToTokens(entries: entries)
        let list = UserTokenList(tokens: tokens)

        saveTokensCancellable = tangemApiService.saveTokens(key: accountId, list: list).sink()
    }
}

// MARK: - Private

private extension CommonUserTokenListManager {
    func loadUserTokenList(result: @escaping (Result<UserTokenList, Error>) -> Void) {
        self.loadTokensCancellable = self.tangemApiService
            .loadTokens(key: self.accountId)
            .sink(receiveCompletion: { [unowned self] completion in
                guard case let .failure(error) = completion else { return }

                if error.statusCode == 404 {
                    saveAllTokenFromRepositoryInBackend(result: result)
                } else {
                    result(.failure(error as Error))
                }

            }, receiveValue: { list in
                result(.success(list))
            })
    }

    func saveAllTokenFromRepositoryInBackend(result: @escaping (Result<UserTokenList, Error>) -> Void) {
        let entries = tokenItemsRepository.getItems(for: cardId)
        let tokens = mapToTokens(entries: entries)
        let list = UserTokenList(tokens: tokens)

        saveTokensCancellable = tangemApiService.saveTokens(key: accountId, list: list)
            .receiveCompletion { [unowned self] completion in
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
        let entries = networks.compactMap { key, tokens -> StorageEntry? in
            guard let blockchainNetwork = getBlockchainNetwork(from: key) else {
                return nil
            }

            let entryTokens = tokens.compactMap { token -> Token? in
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

            return StorageEntry(
                blockchainNetwork: blockchainNetwork,
                tokens: entryTokens
            )
        }

        tokenItemsRepository.append(entries, for: cardId)
    }

    func getBlockchainNetwork(from networkId: String?) -> BlockchainNetwork? {
        guard let networkId = networkId,
              let blockchain = Blockchain(from: networkId) else {
            return nil
        }

        return BlockchainNetwork(blockchain)
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
