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

class CommonUserTokensManager {
    @Injected(\.expressAvailabilityProvider) private var expressAvailabilityProvider: ExpressAvailabilityProvider

    let derivationManager: DerivationManager?
    weak var keysDerivingProvider: KeysDerivingProvider?

    private let userWalletId: UserWalletId
    private let shouldLoadExpressAvailability: Bool
    private let userTokenListManager: UserTokenListManager
    private let walletModelsManager: WalletModelsManager
    private let derivationStyle: DerivationStyle?
    private let existingCurves: [EllipticCurve]
    private let longHashesSupported: Bool
    private var pendingUserTokensSyncCompletions: [() -> Void] = []

    init(
        userWalletId: UserWalletId,
        shouldLoadExpressAvailability: Bool,
        userTokenListManager: UserTokenListManager,
        walletModelsManager: WalletModelsManager,
        derivationStyle: DerivationStyle?,
        derivationManager: DerivationManager?,
        existingCurves: [EllipticCurve],
        longHashesSupported: Bool
    ) {
        self.userWalletId = userWalletId
        self.shouldLoadExpressAvailability = shouldLoadExpressAvailability
        self.userTokenListManager = userTokenListManager
        self.walletModelsManager = walletModelsManager
        self.derivationStyle = derivationStyle
        self.derivationManager = derivationManager
        self.existingCurves = existingCurves
        self.longHashesSupported = longHashesSupported
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
        let entries = try tokenItems.map { tokenItem in
            try validateDerivation(for: tokenItem)
            return StorageEntry(blockchainNetwork: tokenItem.blockchainNetwork, token: tokenItem.token)
        }

        userTokenListManager.update(.append(entries), shouldUpload: shouldUpload)
    }

    private func removeInternal(_ tokenItem: TokenItem, shouldUpload: Bool) {
        guard canRemove(tokenItem) else {
            return
        }

        if let token = tokenItem.token {
            userTokenListManager.update(.removeToken(token, in: tokenItem.blockchainNetwork), shouldUpload: shouldUpload)
        } else {
            userTokenListManager.update(.removeBlockchain(tokenItem.blockchainNetwork), shouldUpload: shouldUpload)
        }
    }

    private func loadSwapAvailabilityStateIfNeeded(forceReload: Bool) {
        guard shouldLoadExpressAvailability else {
            return
        }

        let converter = StorageEntryConverter()
        let tokenItems = converter.convertToTokenItem(userTokenListManager.userTokensList.entries)

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
        walletModelsManager.updateAll(silent: false) { [weak self] in
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
    func deriveIfNeeded(completion: @escaping (Result<Void, Swift.Error>) -> Void) {
        guard
            let derivationManager,
            let interactor = keysDerivingProvider?.keysDerivingInteractor
        else {
            completion(.success(()))
            return
        }

        // Delay to update derivations in derivationManager
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            derivationManager.deriveKeys(interactor: interactor, completion: completion)
        }
    }

    func contains(_ tokenItem: TokenItem) -> Bool {
        let tokenItem = withBlockchainNetwork(tokenItem)

        guard let targetEntry = userTokenListManager.userTokens.first(where: { $0.blockchainNetwork == tokenItem.blockchainNetwork }) else {
            return false
        }

        switch tokenItem {
        case .blockchain:
            return true
        case .token(let token, _):
            return targetEntry.tokens.contains(token)
        }
    }

    func containsDerivationInsensitive(_ tokenItem: TokenItem) -> Bool {
        let tokenItem = withBlockchainNetwork(tokenItem)

        let targetsEntry = userTokenListManager.userTokens.filter {
            $0.blockchainNetwork.blockchain.networkId == tokenItem.blockchainNetwork.blockchain.networkId
        }

        guard targetsEntry.isNotEmpty else {
            return false
        }

        switch tokenItem {
        case .blockchain:
            return true
        case .token(let token, _):
            return targetsEntry.flatMap(\.tokens).contains(token)
        }
    }

    func getAllTokens(for blockchainNetwork: BlockchainNetwork) -> [Token] {
        let items = userTokenListManager.userTokens

        if let network = items.first(where: { $0.blockchainNetwork == blockchainNetwork }) {
            return network.tokens
        }

        return []
    }

    func addTokenItemPrecondition(_ tokenItem: TokenItem) throws {
        if AppUtils().hasLongHashesForSend(tokenItem), !longHashesSupported {
            throw Error.failedSupportedLongHashesTokens(blockchainDisplayName: tokenItem.blockchain.displayName)
        }

        if !existingCurves.contains(tokenItem.blockchain.curve) {
            throw Error.failedSupportedCurve(blockchainDisplayName: tokenItem.blockchain.displayName)
        }

        try validateDerivation(for: tokenItem)
    }

    func add(_ tokenItem: TokenItem) async throws -> String {
        let tokenItem = withBlockchainNetwork(tokenItem)

        try await withCheckedThrowingContinuation { continuation in
            add(tokenItem) { result in
                continuation.resume(with: result)
            }
        }

        // wait for walletModelsManager to be updated
        try await Task.sleep(seconds: 0.1)

        let walletModelId = WalletModelId(tokenItem: tokenItem)

        guard let walletModel = walletModelsManager.walletModels.first(where: { $0.id == walletModelId }) else {
            throw CommonUserTokensManager.Error.addressNotFound
        }

        return walletModel.defaultAddressString
    }

    func add(_ tokenItems: [TokenItem], completion: @escaping (Result<Void, Swift.Error>) -> Void) {
        let tokenItems = tokenItems.map { withBlockchainNetwork($0) }

        do {
            try addInternal(tokenItems, shouldUpload: true)
        } catch {
            completion(.failure(error))
            return
        }

        deriveIfNeeded(completion: completion)
    }

    func canRemove(_ tokenItem: TokenItem, pendingToAddItems: [TokenItem], pendingToRemoveItems: [TokenItem]) -> Bool {
        guard tokenItem.isBlockchain else {
            return true
        }

        let tokenItem = withBlockchainNetwork(tokenItem)

        guard
            let entry = userTokenListManager.userTokens.first(where: { $0.blockchainNetwork == tokenItem.blockchainNetwork })
        else {
            return false
        }

        let tokensToAdd = pendingToAddItems
            .map(withBlockchainNetwork)
            .filter { $0.blockchainNetwork == tokenItem.blockchainNetwork }
            .compactMap(\.token)

        let tokensToRemove = pendingToRemoveItems
            .map(withBlockchainNetwork)
            .filter { $0.blockchainNetwork == tokenItem.blockchainNetwork }
            .compactMap(\.token)

        // Append to list of saved user tokens items that are pending addition, and delete the items that are pending removing
        let tokenList = (entry.tokens + tokensToAdd).filter { !tokensToRemove.contains($0) }

        // We can remove token if there is no items in `tokenList`
        return tokenList.isEmpty
    }

    func remove(_ tokenItem: TokenItem) {
        let tokenItem = withBlockchainNetwork(tokenItem)

        removeInternal(tokenItem, shouldUpload: true)
    }

    func update(itemsToRemove: [TokenItem], itemsToAdd: [TokenItem], completion: @escaping (Result<Void, Swift.Error>) -> Void) {
        let itemsToRemove = itemsToRemove.map { withBlockchainNetwork($0) }
        let itemsToAdd = itemsToAdd.map { withBlockchainNetwork($0) }

        do {
            try update(itemsToRemove: itemsToRemove, itemsToAdd: itemsToAdd)
        } catch {
            completion(.failure(error))
            return
        }

        deriveIfNeeded(completion: completion)
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

    var groupingOption: AnyPublisher<UserTokensReorderingOptions.Grouping, Never> {
        let converter = UserTokensReorderingOptionsConverter()
        return userTokenListManager
            .userTokensListPublisher
            .map { converter.convert($0.grouping) }
            .eraseToAnyPublisher()
    }

    var sortingOption: AnyPublisher<UserTokensReorderingOptions.Sorting, Never> {
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
            .handleEvents(receiveOutput: { input in
                let (userTokensManager, (editedList, existingList)) = input
                let logger = UserTokensReorderingLogger(walletModels: userTokensManager.walletModelsManager.walletModels)
                logger.logReorder(existingList: existingList, editedList: editedList, source: source)
            })
            .receive(on: DispatchQueue.main)
            .map { input in
                let (userTokensManager, (editedList, _)) = input
                userTokensManager.userTokenListManager.update(with: editedList)
            }
        }
        .eraseToAnyPublisher()
    }
}

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
