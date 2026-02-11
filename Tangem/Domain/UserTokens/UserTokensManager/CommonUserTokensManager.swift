//
//  CommonUserTokensManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemLocalization
import Combine
import Foundation
import TangemFoundation
import TangemSdk

@available(iOS, deprecated: 100000.0, message: "Superseded by 'AccountsAwareUserTokensManager', will be removed in the future ([REDACTED_INFO])")
final class CommonUserTokensManager {
    @Injected(\.expressAvailabilityProvider) private var expressAvailabilityProvider: ExpressAvailabilityProvider

    weak var walletModelsManager: WalletModelsManager?
    weak var derivationManager: DerivationManager?

    private let userWalletId: UserWalletId
    private let shouldLoadExpressAvailability: Bool
    private let userTokenListManager: UserTokenListManager
    private let derivationStyle: DerivationStyle?
    private let existingCurves: [EllipticCurve]
    private let hardwareLimitationsUtil: HardwareLimitationsUtil
    private var pendingUserTokensSyncCompletions: [() -> Void] = []

    init(
        userWalletId: UserWalletId,
        shouldLoadExpressAvailability: Bool,
        userTokenListManager: UserTokenListManager,
        derivationStyle: DerivationStyle?,
        existingCurves: [EllipticCurve],
        persistentBlockchains: [TokenItem],
        hardwareLimitationsUtil: HardwareLimitationsUtil
    ) {
        self.userWalletId = userWalletId
        self.shouldLoadExpressAvailability = shouldLoadExpressAvailability
        self.userTokenListManager = userTokenListManager
        self.derivationStyle = derivationStyle
        self.existingCurves = existingCurves
        self.hardwareLimitationsUtil = hardwareLimitationsUtil

        if persistentBlockchains.isNotEmpty {
            try? addInternal(persistentBlockchains, shouldUpload: true)
        }
    }

    private func withBlockchainNetwork(_ tokenItem: TokenItem) -> TokenItem {
        // TokenItem already contains derivation
        guard tokenItem.blockchainNetwork.derivationPath == nil else {
            return tokenItem
        }

        // Derivation unsupported
        guard let derivationStyle else {
            return tokenItem
        }

        let derivationPath = tokenItem.blockchain.derivationPath(for: derivationStyle)
        let blockchainNetwork = BlockchainNetwork(tokenItem.blockchain, derivationPath: derivationPath)

        switch tokenItem {
        case .token(let token, _):
            return .token(token, blockchainNetwork)
        case .blockchain:
            return .blockchain(blockchainNetwork)
        }
    }

    private func addInternal(_ tokenItems: [TokenItem], shouldUpload: Bool) throws {
        let enrichedItems = TokenItemsEnricher.enrichedWithBlockchainNetworksIfNeeded(tokenItems, filter: userTokens)

        for tokenItem in enrichedItems {
            try validateDerivation(for: tokenItem)

            if tokenItem.isToken {
                let networkTokenItem = TokenItem.blockchain(tokenItem.blockchainNetwork)
                try validateDerivation(for: networkTokenItem)
            }
        }

        userTokenListManager.update(.append(enrichedItems), shouldUpload: shouldUpload)
    }

    private func removeInternal(_ tokenItem: TokenItem, shouldUpload: Bool) {
        guard canRemove(tokenItem) else {
            return
        }

        userTokenListManager.update(.remove(tokenItem), shouldUpload: shouldUpload)
    }

    private func loadSwapAvailabilityStateIfNeeded(forceReload: Bool) {
        guard shouldLoadExpressAvailability else {
            return
        }

        let converter = StorageEntryConverter()
        let tokenItems = converter.convertToTokenItems(userTokenListManager.userTokensList.entries)

        expressAvailabilityProvider.updateExpressAvailability(
            for: tokenItems,
            forceReload: forceReload,
            userWalletId: userWalletId.stringValue
        )
    }

    private func validateDerivation(for tokenItem: TokenItem) throws {
        if let derivationPath = tokenItem.blockchainNetwork.derivationPath,
           tokenItem.blockchain.curve == .ed25519_slip0010,
           derivationPath.nodes.contains(where: { !$0.isHardened }) {
            throw TangemSdkError.nonHardenedDerivationNotSupported
        }
    }

    private func handleUserTokensSync() {
        loadSwapAvailabilityStateIfNeeded(forceReload: true)
        Task { [weak self] in
            await self?.walletModelsManager?.updateAll(silent: false)
            self?.handleWalletModelsUpdate()
        }
    }

    private func handleWalletModelsUpdate() {
        let completions = pendingUserTokensSyncCompletions
        pendingUserTokensSyncCompletions.removeAll()
        completions.forEach { $0() }
    }
}

// MARK: - UserTokensManager protocol conformance

extension CommonUserTokensManager: UserTokensManager {
    var initializedPublisher: AnyPublisher<Bool, Never> {
        userTokenListManager.initializedPublisher
    }

    var userTokens: [TokenItem] {
        let converter = StorageEntryConverter()
        return converter.convertToTokenItems(userTokenListManager.userTokensList.entries)
    }

    var userTokensPublisher: AnyPublisher<[TokenItem], Never> {
        let converter = StorageEntryConverter()
        return userTokenListManager.userTokensListPublisher
            .map { converter.convertToTokenItems($0.entries) }
            .eraseToAnyPublisher()
    }

    func deriveIfNeeded(completion: @escaping (Result<Void, Swift.Error>) -> Void) {
        guard let derivationManager else {
            completion(.success(()))
            return
        }

        // Delay to update derivations in derivationManager
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            derivationManager.deriveKeys(completion: completion)
        }
    }

    func contains(_ tokenItem: TokenItem, derivationInsensitive: Bool) -> Bool {
        let tokenItem = withBlockchainNetwork(tokenItem)

        return userTokens.contains { existingTokenItem in
            return derivationInsensitive
                ? existingTokenItem.blockchain.networkId == tokenItem.blockchain.networkId && existingTokenItem.token == tokenItem.token
                : existingTokenItem == tokenItem
        }
    }

    func needsCardDerivation(itemsToRemove: [TokenItem], itemsToAdd: [TokenItem]) -> Bool {
        guard let derivationManager else {
            return false
        }

        // Filter only blockchains because we don't care about removing tokens from network.
        let networksToRemove = itemsToRemove
            .filter { $0.isBlockchain }
            .map { withBlockchainNetwork($0) }
            .map(\.blockchainNetwork)

        let networksToAdd = itemsToAdd
            .map { withBlockchainNetwork($0) }
            .map(\.blockchainNetwork)

        return derivationManager.shouldDeriveKeys(
            networksToRemove: networksToRemove,
            networksToAdd: networksToAdd
        )
    }

    func addTokenItemHardwarePrecondition(_ tokenItem: TokenItem) throws {
        guard hardwareLimitationsUtil.canAdd(tokenItem) else {
            throw Error.failedSupportedLongHashesTokens(blockchainDisplayName: tokenItem.blockchain.displayName)
        }

        if !existingCurves.contains(tokenItem.blockchain.curve) {
            throw Error.failedSupportedCurve(blockchainDisplayName: tokenItem.blockchain.displayName)
        }
    }

    func addTokenItemPrecondition(_ tokenItem: TokenItem) throws {
        try addTokenItemHardwarePrecondition(tokenItem)
        try validateDerivation(for: tokenItem)
    }

    func add(_ tokenItem: TokenItem) async throws -> String {
        let tokenItem = withBlockchainNetwork(tokenItem)

        let addedToken = try await withCheckedThrowingContinuation { continuation in
            add(tokenItem) { result in
                switch result {
                case .success(let addedTokenItem):
                    continuation.resume(returning: addedTokenItem)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }

        // wait for walletModelsManager to be updated
        try await Task.sleep(for: .seconds(0.1))

        let walletModelId = WalletModelId(tokenItem: addedToken)

        guard let walletModel = walletModelsManager?.walletModels.first(where: { $0.id == walletModelId }) else {
            throw Error.addressNotFound
        }

        return walletModel.defaultAddressString
    }

    func add(_ tokenItems: [TokenItem], completion: @escaping (Result<[TokenItem], Swift.Error>) -> Void) {
        let tokenItems = tokenItems.map { withBlockchainNetwork($0) }

        do {
            try addInternal(tokenItems, shouldUpload: true)
        } catch {
            completion(.failure(error))
            return
        }

        deriveIfNeeded { result in
            switch result {
            case .success:
                completion(.success(tokenItems))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func canRemove(_ tokenItem: TokenItem, pendingToAddItems: [TokenItem], pendingToRemoveItems: [TokenItem]) -> Bool {
        guard tokenItem.isBlockchain else {
            return true
        }

        let tokenItem = withBlockchainNetwork(tokenItem)

        let existingTokens = userTokens
            .filter { $0.blockchainNetwork == tokenItem.blockchainNetwork }
            .compactMap(\.token)

        let tokensToAdd = pendingToAddItems
            .map(withBlockchainNetwork)
            .filter { $0.blockchainNetwork == tokenItem.blockchainNetwork }
            .compactMap(\.token)

        let tokensToRemove = pendingToRemoveItems
            .map(withBlockchainNetwork)
            .filter { $0.blockchainNetwork == tokenItem.blockchainNetwork }
            .compactMap(\.token)

        // Append to list of saved user tokens items that are pending addition, and delete the items that are pending removing
        let tokenList = (existingTokens + tokensToAdd).filter { !tokensToRemove.contains($0) }

        // We can remove token if there is no items in `tokenList`
        return tokenList.isEmpty
    }

    func remove(_ tokenItem: TokenItem) {
        let tokenItem = withBlockchainNetwork(tokenItem)

        removeInternal(tokenItem, shouldUpload: true)
    }

    func update(
        itemsToRemove: [TokenItem],
        itemsToAdd: [TokenItem],
        completion: @escaping (Result<UserTokensManagerResult.UpdatedTokenItems, Swift.Error>) -> Void
    ) {
        let itemsToRemove = itemsToRemove.map { withBlockchainNetwork($0) }
        let itemsToAdd = itemsToAdd.map { withBlockchainNetwork($0) }

        do {
            try update(itemsToRemove: itemsToRemove, itemsToAdd: itemsToAdd)
        } catch {
            completion(.failure(error))
            return
        }

        deriveIfNeeded { result in
            switch result {
            case .success:
                let updatedItems = UserTokensManagerResult.UpdatedTokenItems(removed: itemsToRemove, added: itemsToAdd)
                completion(.success(updatedItems))

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func update(itemsToRemove: [TokenItem], itemsToAdd: [TokenItem]) throws {
        let itemsToRemove = itemsToRemove.map { withBlockchainNetwork($0) }
        let itemsToAdd = itemsToAdd.map { withBlockchainNetwork($0) }

        itemsToRemove.forEach {
            removeInternal($0, shouldUpload: false)
        }

        try addInternal(itemsToAdd, shouldUpload: false)
        loadSwapAvailabilityStateIfNeeded(forceReload: true)
        userTokenListManager.upload()
    }

    func sync(completion: @escaping () -> Void) {
        defer {
            pendingUserTokensSyncCompletions.append(completion)
        }

        // Initiate a new update only if there is no ongoing update (i.e. `pendingUserTokensSyncCompletions` is empty)
        guard pendingUserTokensSyncCompletions.isEmpty else {
            return
        }

        userTokenListManager.updateLocalRepositoryFromServer { [weak self] _ in
            self?.handleUserTokensSync()
        }
    }
}

// MARK: - UserTokensReordering protocol conformance

extension CommonUserTokensManager: UserTokensReordering {
    var orderedWalletModelIds: AnyPublisher<[WalletModelId.ID], Never> {
        return userTokenListManager
            .userTokensListPublisher
            .map { $0.entries.map(\.walletModelId.id) }
            .eraseToAnyPublisher()
    }

    var groupingOption: UserTokensReorderingOptions.Grouping {
        let converter = UserTokensReorderingOptionsConverter()
        return converter.convert(userTokenListManager.userTokensList.grouping)
    }

    var sortingOption: UserTokensReorderingOptions.Sorting {
        let converter = UserTokensReorderingOptionsConverter()
        return converter.convert(userTokenListManager.userTokensList.sorting)
    }

    var groupingOptionPublisher: AnyPublisher<UserTokensReorderingOptions.Grouping, Never> {
        let converter = UserTokensReorderingOptionsConverter()
        return userTokenListManager
            .userTokensListPublisher
            .map { converter.convert($0.grouping) }
            .eraseToAnyPublisher()
    }

    var sortingOptionPublisher: AnyPublisher<UserTokensReorderingOptions.Sorting, Never> {
        let converter = UserTokensReorderingOptionsConverter()
        return userTokenListManager
            .userTokensListPublisher
            .map { converter.convert($0.sorting) }
            .eraseToAnyPublisher()
    }

    func reorder(_ actions: [UserTokensReorderingAction], source: UserTokensReorderingSource) -> AnyPublisher<Void, Never> {
        if actions.isEmpty {
            return .just
        }

        return Deferred { [userTokenListManager = self.userTokenListManager] in
            Future { promise in
                let converter = UserTokensReorderingOptionsConverter()
                let existingList = userTokenListManager.userTokensList
                var entries = existingList.entries
                var grouping = existingList.grouping
                var sorting = existingList.sorting

                for action in actions {
                    switch action {
                    case .setGroupingOption(let option):
                        grouping = converter.convert(option)
                    case .setSortingOption(let option):
                        sorting = converter.convert(option)
                    case .reorder(let reorderedWalletModelIds):
                        let userTokensKeyedByIds = entries.keyedFirst(by: \.walletModelId.id)
                        let reorderedEntries = reorderedWalletModelIds.compactMap { userTokensKeyedByIds[$0] }

                        // [REDACTED_TODO_COMMENT]
                        if reorderedEntries.count == entries.count {
                            entries = reorderedEntries
                        }
                    }
                }

                let editedList = StoredUserTokenList(
                    entries: entries,
                    grouping: grouping,
                    sorting: sorting
                )

                promise(.success((editedList, existingList)))
            }
            .filter { $0 != $1 }
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .map { input in
                let (userTokensManager, (editedList, _)) = input
                userTokensManager.userTokenListManager.update(with: editedList)
            }
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - UserTokensPushNotificationsRemoteStatusSyncing protocol conformance

extension CommonUserTokensManager: UserTokensPushNotificationsRemoteStatusSyncing {
    func syncRemoteStatus() {
        userTokenListManager.upload()
    }
}

// MARK: - Auxiliary types

extension CommonUserTokensManager {
    enum Error: LocalizedError {
        case addressNotFound
        case failedSupportedLongHashesTokens(blockchainDisplayName: String)
        case failedSupportedCurve(blockchainDisplayName: String)

        var errorDescription: String? {
            switch self {
            case .failedSupportedLongHashesTokens(let blockchainDisplayName):
                return Localization.alertManageTokensUnsupportedMessage(blockchainDisplayName)
            case .failedSupportedCurve(let blockchainDisplayName):
                return Localization.alertManageTokensUnsupportedCurveMessage(blockchainDisplayName)
            case .addressNotFound:
                return Localization.genericErrorCode(errorCode)
            }
        }
    }
}
