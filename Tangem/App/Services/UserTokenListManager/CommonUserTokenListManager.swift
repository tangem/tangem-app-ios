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

    private let userWalletId: Data
    private let tokenItemsRepository: TokenItemsRepository
    private let supportedBlockchains: Set<Blockchain>

    // hotfix migration
    private let hdWalletsSupported: Bool

    private let hasTokenSynchronization: Bool

    private let _initialSync: CurrentValueSubject<Bool, Never>
    private let _userTokens: CurrentValueSubject<[StorageEntry.V3.Entry], Never>
    private let _groupingOption: CurrentValueSubject<StorageEntry.V3.Grouping, Never>
    private let _sortingOption: CurrentValueSubject<StorageEntry.V3.Sorting, Never>

    private var pendingTokensToUpdate: UserTokenList?
    private var loadTokensCancellable: AnyCancellable?
    private var saveTokensCancellable: AnyCancellable?

    /// Bool flag for migration custom token to token form our API
    private var migrated = false

    init(
        userWalletId: Data,
        tokenItemsRepository: TokenItemsRepository,
        supportedBlockchains: Set<Blockchain>,
        hdWalletsSupported: Bool,
        hasTokenSynchronization: Bool
    ) {
        self.userWalletId = userWalletId
        self.supportedBlockchains = supportedBlockchains
        self.hdWalletsSupported = hdWalletsSupported
        self.hasTokenSynchronization = hasTokenSynchronization
        self.tokenItemsRepository = tokenItemsRepository

        _initialSync = CurrentValueSubject(tokenItemsRepository.isInitialized)
        _userTokens = CurrentValueSubject(tokenItemsRepository.getItems())
        _groupingOption = CurrentValueSubject(tokenItemsRepository.groupingOption)
        _sortingOption = CurrentValueSubject(tokenItemsRepository.sortingOption)

        removeInvalidTokens()
        performInitialSync()
    }

    private func performInitialSync() {
        if isInitialSyncPerformed {
            return
        }

        updateLocalRepositoryFromServer { [weak self] _ in
            self?._initialSync.send(true)
        }
    }
}

// MARK: - UserTokenListManager protocol conformance

extension CommonUserTokenListManager: UserTokenListManager {
    var userTokens: [StorageEntry.V3.Entry] {
        _userTokens.value
    }

    var userTokensPublisher: AnyPublisher<[StorageEntry.V3.Entry], Never> {
        _userTokens.eraseToAnyPublisher()
    }

    var groupingOptionPublisher: AnyPublisher<StorageEntry.V3.Grouping, Never> {
        _groupingOption.eraseToAnyPublisher()
    }

    var sortingOptionPublisher: AnyPublisher<StorageEntry.V3.Sorting, Never> {
        _sortingOption.eraseToAnyPublisher()
    }

    func update(_ updates: [UserTokenListUpdateType], shouldUpload: Bool) {
        guard !updates.isEmpty else { return }

        for update in updates {
            switch update {
            case .rewrite(let entries):
                tokenItemsRepository.update(entries)
            case .append(let entries):
                tokenItemsRepository.append(entries)
            case .removeBlockchain(let blockchain):
                tokenItemsRepository.remove([blockchain])
            case .removeToken(let token, let network):
                let converter = StorageEntriesConverter()
                let storageEntry = converter.convert(token, in: network)
                tokenItemsRepository.remove([storageEntry])
            case .group(let groupingOption):
                tokenItemsRepository.groupingOption = groupingOption
            case .sort(let sortingOption):
                tokenItemsRepository.sortingOption = sortingOption
            }
        }

        notifyAboutTokenListUpdates()

        if shouldUpload {
            updateTokenListOnServer()
        }
    }

    func updateLocalRepositoryFromServer(result: @escaping (Result<Void, Error>) -> Void) {
        guard hasTokenSynchronization else {
            result(.success(()))
            return
        }

        loadUserTokenList(result: result)
    }

    func updateServerFromLocalRepository() {
        guard hasTokenSynchronization else { return }

        updateTokenListOnServer()
    }
}

// MARK: - UserTokensSyncService protocol conformance

extension CommonUserTokenListManager: UserTokensSyncService {
    var isInitialSyncPerformed: Bool {
        tokenItemsRepository.isInitialized
    }

    var initialSyncPublisher: AnyPublisher<Bool, Never> {
        _initialSync.eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension CommonUserTokenListManager {
    func notifyAboutTokenListUpdates() {
        _userTokens.send(tokenItemsRepository.getItems())
        _sortingOption.send(tokenItemsRepository.sortingOption)
        _groupingOption.send(tokenItemsRepository.groupingOption)
    }

    // MARK: - Requests

    func loadUserTokenList(result: @escaping (Result<Void, Error>) -> Void) {
        if let list = pendingTokensToUpdate {
            pendingTokensToUpdate = nil
            updateTokenItemsRepository(with: list)
            updateTokenListOnServer(list, result: result)

            return
        }

        let loadTokensPublisher = tangemApiService.loadTokens(for: userWalletId.hexString)
        let upgradeTokensPublisher = tryMigrateTokens().setFailureType(to: TangemAPIError.self)

        self.loadTokensCancellable = loadTokensPublisher
            .combineLatest(upgradeTokensPublisher)
            .sink { [unowned self] completion in
                guard case .failure(let error) = completion else { return }

                if error.code == .notFound {
                    updateTokenListOnServer(result: result)
                } else {
                    result(.failure(error as Error))
                }
            } receiveValue: { [unowned self] list, _ in
                updateTokenItemsRepository(with: list)
                notifyAboutTokenListUpdates()
                result(.success(()))
            }
    }

    func updateTokenListOnServer(
        _ list: UserTokenList? = nil,
        result: @escaping (Result<Void, Error>) -> Void = { _ in }
    ) {
        let listToUpdate = list ?? getUserTokenList()

        saveTokensCancellable = tangemApiService
            .saveTokens(list: listToUpdate, for: userWalletId.hexString)
            .receiveCompletion { [unowned self] completion in
                switch completion {
                case .finished:
                    result(.success(()))
                case .failure(let error):
                    self.pendingTokensToUpdate = listToUpdate
                    result(.failure(error))
                }
            }
    }

    func updateTokenItemsRepository(with list: UserTokenList) {
        let converter = UserTokenListConverter(supportedBlockchains: supportedBlockchains)

        tokenItemsRepository.update(converter.convertToEntries(tokens: list.tokens))
        tokenItemsRepository.groupingOption = converter.convertToGroupingOption(groupType: list.group)
        tokenItemsRepository.sortingOption = converter.convertToSortingOption(sortType: list.sort)
    }

    func getUserTokenList() -> UserTokenList {
        let entries = tokenItemsRepository.getItems()
        let groupingOption = tokenItemsRepository.groupingOption
        let sortingOption = tokenItemsRepository.sortingOption
        let converter = UserTokenListConverter(supportedBlockchains: supportedBlockchains)

        return UserTokenList(
            tokens: converter.convertToTokens(entries: entries),
            group: converter.convertToGroupType(groupingOption: groupingOption),
            sort: converter.convertToSortType(sortingOption: sortingOption)
        )
    }

    // MARK: - Token upgrading

    func tryMigrateTokens() -> AnyPublisher<Void, Never> {
        if migrated {
            return .just
        }

        migrated = true

        let items = tokenItemsRepository.getItems()
        let customTokens = items.filter { $0.isToken && $0.isCustom }

        if customTokens.isEmpty {
            return .just
        }

        let publishers = customTokens.map(updateCustomToken(_:))

        return Publishers.MergeMany(publishers)
            .collect(publishers.count)
            .mapVoid()
            .eraseToAnyPublisher()
    }

    func updateCustomToken(_ storageEntry: StorageEntry.V3.Entry) -> AnyPublisher<Bool, Never> {
        let blockchainNetwork = storageEntry.blockchainNetwork
        let requestModel = CoinsList.Request(
            supportedBlockchains: [blockchainNetwork.blockchain],
            contractAddress: storageEntry.contractAddress
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

                    let converter = StorageEntriesConverter()
                    let updatedStorageEntry = converter.convert(token, in: blockchainNetwork)
                    self?.update(.append([updatedStorageEntry]), shouldUpload: true)
                    promise(.success(true))
                }
                .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    // Remove tokens with derivation for cards without derivation
    private func removeInvalidTokens() {
        guard !hdWalletsSupported else {
            return
        }

        let allItems = tokenItemsRepository.getItems()
        let badItems = allItems.filter { $0.blockchainNetwork.derivationPath != nil }
        guard !badItems.isEmpty else {
            return
        }

        let networks = badItems.map { $0.blockchainNetwork }
        tokenItemsRepository.remove(networks)
    }
}
