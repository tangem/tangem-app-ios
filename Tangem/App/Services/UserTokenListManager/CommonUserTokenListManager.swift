//
//  CommonUserTokenListManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

import enum BlockchainSdk.Blockchain
import struct BlockchainSdk.Token
import struct TangemSdk.DerivationPath

class CommonUserTokenListManager {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    private var userWalletId: Data
    private var tokenItemsRepository: TokenItemsRepository

    private var loadTokensCancellable: AnyCancellable?
    private var saveTokensCancellable: AnyCancellable?

    init(config: UserWalletConfig, userWalletId: Data) {
        self.userWalletId = userWalletId

        tokenItemsRepository = CommonTokenItemsRepository(key: userWalletId.hexString)
    }
}

// MARK: - UserTokenListManager

extension CommonUserTokenListManager: UserTokenListManager {
    func update(userWalletId: Data) {
        self.userWalletId = userWalletId
        tokenItemsRepository = CommonTokenItemsRepository(key: userWalletId.hexString)
    }

    func update(_ type: UpdateType, result: @escaping (Result<UserTokenList, Error>) -> Void) {
        switch type {
        case let .rewrite(entries):
            update(entries: entries, result: result)
        case let .append(entries):
            append(entries: entries, result: result)
        case let .removeBlockchain(blockchain):
            remove(blockchain: blockchain, result: result)
        case let .removeToken(token, network):
            remove(token: token, in: network, result: result)
        }
    }

    func getEntriesFromRepository() -> [StorageEntry] {
        tokenItemsRepository.getItems()
    }

    func clearRepository(result: @escaping (Result<UserTokenList, Error>) -> Void) {
        tokenItemsRepository.removeAll()
        updateTokensOnServer(result: result)
    }

    func loadAndSaveUserTokenList(result: @escaping (Result<UserTokenList, Error>) -> Void) {
        loadUserTokenList(result: result)
    }
}

// MARK: - Private

private extension CommonUserTokenListManager {
    func update(entries: [StorageEntry], result: @escaping (Result<UserTokenList, Error>) -> Void) {
        tokenItemsRepository.update(entries)
        updateTokensOnServer(result: result)
    }

    func append(entries: [StorageEntry], result: @escaping (Result<UserTokenList, Error>) -> Void) {
        tokenItemsRepository.append(entries)
        updateTokensOnServer(result: result)
    }

    func remove(blockchain: BlockchainNetwork, result: @escaping (Result<UserTokenList, Error>) -> Void) {
        tokenItemsRepository.remove([blockchain])
        updateTokensOnServer(result: result)
    }

    func remove(token: Token, in blockchain: BlockchainNetwork, result: @escaping (Result<UserTokenList, Error>) -> Void) {
        tokenItemsRepository.remove([token], blockchainNetwork: blockchain)
        updateTokensOnServer(result: result)
    }

    // MARK: - Requests

    func loadUserTokenList(result: @escaping (Result<UserTokenList, Error>) -> Void) {
        self.loadTokensCancellable = tangemApiService
            .loadTokens(for: userWalletId.hexString)
            .sink { [unowned self] completion in
                guard case let .failure(error) = completion else { return }

                if error.code == .notFound {
                    updateTokensOnServer(result: result)
                } else {
                    result(.failure(error as Error))
                }
            } receiveValue: { [unowned self] list in
                tokenItemsRepository.update(mapToEntries(list: list))
                result(.success(list))
            }
    }

    func updateTokensOnServer(result: @escaping (Result<UserTokenList, Error>) -> Void) {
        let entries = tokenItemsRepository.getItems()
        let tokens = mapToTokens(entries: entries)
        let list = UserTokenList(tokens: tokens)

        saveTokensCancellable = tangemApiService
            .saveTokens(list: list, for: userWalletId.hexString)
            .receiveCompletion { completion in
                switch completion {
                case .finished:
                    result(.success(list))
                case let .failure(error):
                    result(.failure(error))
                }
            }
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
                derivationPath: entry.blockchainNetwork.derivationPath,
                contractAddress: nil
            )]

            result += entry.tokens.map { token in
                UserTokenList.Token(
                    id: token.id,
                    networkId: blockchain.networkId,
                    name: token.name,
                    symbol: token.symbol,
                    decimals: token.decimalCount,
                    derivationPath: entry.blockchainNetwork.derivationPath,
                    contractAddress: token.contractAddress
                )
            }
        }
    }

    func mapToEntries(list: UserTokenList) -> [StorageEntry] {
        let blockchains = list.tokens
            .filter { $0.contractAddress == nil }
            .compactMap { token -> BlockchainNetwork? in
                guard let blockchain = Blockchain(from: token.networkId) else {
                    return nil
                }

                return BlockchainNetwork(blockchain, derivationPath: token.derivationPath)
            }

        let entries: [StorageEntry] = blockchains.map { network in
            return StorageEntry(
                blockchainNetwork: network,
                tokens: list.tokens
                    .filter { $0.contractAddress != nil && $0.networkId == network.blockchain.networkId }
                    .map { token in
                        Token(
                            name: token.name,
                            symbol: token.symbol,
                            contractAddress: token.contractAddress!,
                            decimalCount: token.decimals,
                            id: token.id
                        )
                    }
            )
        }

        return entries
    }
}

extension CommonUserTokenListManager {
    enum UpdateType {
        case rewrite(_ entries: [StorageEntry])
        case append(_ entries: [StorageEntry])
        case removeBlockchain(_ blockchain: BlockchainNetwork)
        case removeToken(_ token: Token, in: BlockchainNetwork)
    }
}
