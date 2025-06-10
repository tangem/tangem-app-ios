//
//  CommonUserTokenListManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import enum BlockchainSdk.Blockchain
import struct BlockchainSdk.Token
import struct TangemSdk.DerivationPath

class CommonUserTokenListManager {
    typealias Completion = (Result<Void, Swift.Error>) -> Void

    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    private let userWalletId: Data
    private let supportedBlockchains: Set<Blockchain>
    private let hasTokenSynchronization: Bool
    private let hdWalletsSupported: Bool // hotfix migration
    private let defaultBlockchains: [StorageEntry]

    private let tokenItemsRepository: TokenItemsRepository
    private let userTokensListSubject: CurrentValueSubject<StoredUserTokenList, Never>

    private var pendingTokensToUpdate: UserTokenList?
    private var loadTokensCancellable: AnyCancellable?
    private var saveTokensCancellable: AnyCancellable?
    private var initializedSubject: CurrentValueSubject<Bool, Never>

    /// Bool flag for migration custom token to token form our API
    private var migrated = false

    init(
        userWalletId: Data,
        supportedBlockchains: Set<Blockchain>,
        hdWalletsSupported: Bool,
        hasTokenSynchronization: Bool,
        defaultBlockchains: [StorageEntry]
    ) {
        self.userWalletId = userWalletId
        self.supportedBlockchains = supportedBlockchains
        self.hdWalletsSupported = hdWalletsSupported
        self.hasTokenSynchronization = hasTokenSynchronization
        self.defaultBlockchains = defaultBlockchains
        tokenItemsRepository = CommonTokenItemsRepository(key: userWalletId.hexString)
        initializedSubject = CurrentValueSubject(tokenItemsRepository.containsFile)
        userTokensListSubject = CurrentValueSubject(tokenItemsRepository.getList())

        removeInvalidTokens()
    }
}

// MARK: - UserTokenListManager

extension CommonUserTokenListManager: UserTokenListManager {
    var initialized: Bool {
        initializedSubject.value
    }

    var initializedPublisher: AnyPublisher<Bool, Never> {
        initializedSubject.eraseToAnyPublisher()
    }

    var userTokens: [StorageEntry] {
        let converter = StorageEntryConverter()
        return converter.convertToStorageEntries(userTokensListSubject.value.entries)
    }

    var userTokensPublisher: AnyPublisher<[StorageEntry], Never> {
        let converter = StorageEntryConverter()
        return userTokensListSubject
            .map { converter.convertToStorageEntries($0.entries) }
            .eraseToAnyPublisher()
    }

    var userTokensList: StoredUserTokenList {
        userTokensListSubject.value
    }

    var userTokensListPublisher: AnyPublisher<StoredUserTokenList, Never> {
        userTokensListSubject
            .eraseToAnyPublisher()
    }

    func update(with userTokenList: StoredUserTokenList) {
        tokenItemsRepository.update(userTokenList)
        notifyAboutTokenListUpdates(with: userTokenList)

        let converter = UserTokenListConverter(supportedBlockchains: supportedBlockchains)
        updateTokensOnServer(list: converter.convertStoredToRemote(userTokenList))
    }

    func update(_ type: UserTokenListUpdateType, shouldUpload: Bool) {
        let converter = StorageEntryConverter()

        switch type {
        case .append(let entries):
            let storedUserTokens = converter.convertToStoredUserTokens(entries)
            tokenItemsRepository.append(storedUserTokens)
        case .removeBlockchain(let blockchainNetwork):
            tokenItemsRepository.remove([blockchainNetwork])
        case .removeToken(let token, let blockchainNetwork):
            let storedUserToken = converter.convertToStoredUserToken(token, in: blockchainNetwork)
            tokenItemsRepository.remove([storedUserToken])
        }

        notifyAboutTokenListUpdates()

        if shouldUpload {
            updateTokensOnServer()
        }
    }

    func updateLocalRepositoryFromServer(_ completion: @escaping Completion) {
        guard hasTokenSynchronization else {
            completion(.success(()))
            return
        }

        loadUserTokenList(completion)
    }

    func upload() {
        updateTokensOnServer()
    }
}

// MARK: - Private

private extension CommonUserTokenListManager {
    func notifyAboutTokenListUpdates(with userTokenList: StoredUserTokenList? = nil) {
        let updatedUserTokenList = userTokenList ?? tokenItemsRepository.getList()
        userTokensListSubject.send(updatedUserTokenList)

        if !initialized, tokenItemsRepository.containsFile {
            initializedSubject.send(true)
        }
    }

    // MARK: - Requests

    func loadUserTokenList(_ completion: @escaping Completion) {
        if let list = pendingTokensToUpdate {
            let converter = UserTokenListConverter(supportedBlockchains: supportedBlockchains)

            tokenItemsRepository.update(converter.convertRemoteToStored(list))
            updateTokensOnServer(list: list, completion: completion)
            pendingTokensToUpdate = nil

            return
        }

        let loadTokensPublisher = tangemApiService.loadTokens(for: userWalletId.hexString)
        let upgradeTokensPublisher = tryMigrateTokens().setFailureType(to: TangemAPIError.self)

        loadTokensCancellable = loadTokensPublisher
            .combineLatest(upgradeTokensPublisher)
            .sink { subscriberCompletion in
                switch subscriberCompletion {
                case .finished:
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            } receiveValue: { [weak self] list, _ in
                guard let self else { return }

                if let list {
                    let converter = UserTokenListConverter(supportedBlockchains: supportedBlockchains)
                    let updatedUserTokenList = converter.convertRemoteToStored(list)
                    tokenItemsRepository.update(updatedUserTokenList)
                    notifyAboutTokenListUpdates(with: updatedUserTokenList)
                } else {
                    let converter = StorageEntryConverter()
                    let entries = converter.convertToStoredUserTokens(defaultBlockchains)
                    let newList = StoredUserTokenList(entries: entries, grouping: .none, sorting: .manual)
                    update(with: newList)
                }
            }
    }

    func updateTokensOnServer(list: UserTokenList? = nil, completion: Completion? = nil) {
        guard hasTokenSynchronization else {
            completion?(.success(()))
            return
        }

        let listToUpdate = list ?? getUserTokenList()

        saveTokensCancellable = tangemApiService
            .saveTokens(list: listToUpdate, for: userWalletId.hexString)
            .receiveCompletion { [weak self] subscriberCompletion in
                guard let self else { return }

                switch subscriberCompletion {
                case .finished:
                    completion?(.success(()))
                case .failure(let error):
                    pendingTokensToUpdate = listToUpdate
                    completion?(.failure(error))
                }
            }
    }

    func getUserTokenList() -> UserTokenList {
        let converter = UserTokenListConverter(supportedBlockchains: supportedBlockchains)
        let list = tokenItemsRepository.getList()
        return converter.convertStoredToRemote(list)
    }

    // MARK: - Token upgrading

    func tryMigrateTokens() -> AnyPublisher<Void, Never> {
        if migrated {
            return .just
        }

        migrated = true

        let list = tokenItemsRepository.getList()
        let customUserTokens = list.entries.filter { $0.isCustom }

        if customUserTokens.isEmpty {
            return .just
        }

        let publishers = customUserTokens.map(updateCustomToken(_:))

        return Publishers.MergeMany(publishers)
            .collect(publishers.count)
            .mapToVoid()
            .eraseToAnyPublisher()
    }

    func updateCustomToken(_ token: StoredUserTokenList.Entry) -> AnyPublisher<Bool, Never> {
        let blockchainNetwork = token.blockchainNetwork

        let requestModel = CoinsList.Request(
            supportedBlockchains: [blockchainNetwork.blockchain],
            contractAddress: token.contractAddress
        )

        // [REDACTED_TODO_COMMENT]
        return tangemApiService
            .loadCoins(requestModel: requestModel)
            .replaceError(with: [])
            .flatMap { [weak self] models -> AnyPublisher<Bool, Never> in
                return Future<Bool, Never> { promise in
                    guard let token = models.first?.items.compactMap({ $0.token }).first else {
                        promise(.success(false))
                        return
                    }
                    let entry = StorageEntry(blockchainNetwork: blockchainNetwork, token: token)
                    self?.update(.append([entry]), shouldUpload: true)
                    promise(.success(true))
                }
                .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    /// Remove tokens with derivation for cards without derivation
    func removeInvalidTokens() {
        guard !hdWalletsSupported else {
            return
        }

        let list = tokenItemsRepository.getList()
        let badEntries = list.entries.filter { $0.blockchainNetwork.derivationPath != nil }

        guard !badEntries.isEmpty else {
            return
        }

        let blockchainNetwork = badEntries.map { $0.blockchainNetwork }
        tokenItemsRepository.remove(blockchainNetwork)
    }
}
