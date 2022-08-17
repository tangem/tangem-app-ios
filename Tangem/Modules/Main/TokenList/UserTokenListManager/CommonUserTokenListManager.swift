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
        tangemApiService.loadTokens(key: accountId)
            .handleEvents(receiveOutput: { [weak self] list in
                self?.saveTokenListInRepository(list: list)
            })
            .eraseToAnyPublisher()
    }
}

// MARK: - TokenItemsRepositoryChanges

extension CommonUserTokenListManager: TokenItemsRepositoryChanges {
    func repositoryDidUpdates(entries: [StorageEntry]) {
        let tokens: [UserTokenList.Token] = entries.reduce(into: []) { result, entry in
            let blockchain = entry.blockchainNetwork.blockchain
            result += [UserTokenList.Token(
                id: blockchain.id,
                networkId: blockchain.networkId,
                derivationPath: blockchain.derivationPath()?.rawPath,
                name: blockchain.displayName,
                symbol: blockchain.currencySymbol,
                decimals: blockchain.decimalCount,
                contractAddress: nil
            )]

            result += entry.tokens.map { token in
                UserTokenList.Token(
                    id: token.id,
                    networkId: blockchain.networkId,
                    derivationPath: blockchain.derivationPath()?.rawPath,
                    name: token.name,
                    symbol: token.symbol,
                    decimals: token.decimalCount,
                    contractAddress: token.contractAddress
                )
            }
        }

        let list = UserTokenList(tokens: tokens)

        saveTokenListInBackend(list: list)
    }
}

// MARK: - Private

private extension CommonUserTokenListManager {
    func saveTokenListInBackend(list: UserTokenList) {
        saveTokensCancellable = tangemApiService.saveTokens(key: accountId, list: list).sink()
    }

    func saveTokenListInRepository(list: UserTokenList) {
        let networks = Dictionary(grouping: list.tokens, by: { $0.networkId })
        let entries: [StorageEntry] = networks.map { key, tokens in

            let entryTokens: [Token] = tokens.map { token in
                return Token(
                    name: token.name,
                    symbol: token.symbol,
                    contractAddress: token.contractAddress ?? "contractAddress",
                    decimalCount: token.decimals,
                    id: token.id
                )
            }

            return StorageEntry(
                blockchainNetwork: getBlockchainNetwork(from: key),
                tokens: entryTokens
            )
        }

        tokenItemsRepository.append(entries, for: cardId)
    }

    func getBlockchainNetwork(from networkId: String?) -> BlockchainNetwork {
        guard let networkId = networkId,
              let blockchain = Blockchain(from: networkId) else {
            fatalError()
//            return nil
        }

        return BlockchainNetwork(blockchain)
    }
}
