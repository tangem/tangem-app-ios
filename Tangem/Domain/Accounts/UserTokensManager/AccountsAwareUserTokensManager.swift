//
//  AccountsAwareUserTokensManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemSdk
import TangemFoundation
import TangemLocalization

/// Copy-paste of `CommonUserTokensManager`, but with accounts support.
final class AccountsAwareUserTokensManager {
    @Injected(\.expressAvailabilityProvider) private var expressAvailabilityProvider: ExpressAvailabilityProvider

    weak var walletModelsManager: WalletModelsManager?
    weak var derivationManager: DerivationManager?

    private let userWalletId: UserWalletId
    private let userTokensRepository: UserTokensRepository
    private let derivationInfo: DerivationInfo
    private let existingCurves: [EllipticCurve]
    private let shouldLoadExpressAvailability: Bool
    private let hardwareLimitationsUtil: HardwareLimitationsUtil
    private var pendingUserTokensSyncCompletions: [() -> Void] = []

    private var isMainAccountManager: Bool {
        AccountModelUtils.isMainAccount(derivationInfo.derivationIndex)
    }

    init(
        userWalletId: UserWalletId,
        userTokensRepository: UserTokensRepository,
        derivationInfo: DerivationInfo,
        existingCurves: [EllipticCurve],
        persistentBlockchains: [TokenItem],
        shouldLoadExpressAvailability: Bool,
        hardwareLimitationsUtil: HardwareLimitationsUtil
    ) {
        self.userWalletId = userWalletId
        self.userTokensRepository = userTokensRepository
        self.derivationInfo = derivationInfo
        self.existingCurves = existingCurves
        self.shouldLoadExpressAvailability = shouldLoadExpressAvailability
        self.hardwareLimitationsUtil = hardwareLimitationsUtil

        if persistentBlockchains.isNotEmpty {
            userTokensRepository.performBatchUpdates { updater in
                try? addInternal(persistentBlockchains, using: updater)
            }
        }
    }

    private func withBlockchainNetwork(_ tokenItem: TokenItem) -> TokenItem {
        let blockchain = tokenItem.blockchain
        let derivationPathHelper = AccountDerivationPathHelper(blockchain: blockchain)
        let derivationPath = tokenItem.blockchainNetwork.derivationPath

        // In case when a token item already contains derivation such token item can be added to the main account as is
        if isMainAccountManager, derivationPath != nil {
            return makeTokenItem(from: tokenItem, with: derivationPath)
        }

        // Non-main account with existing derivation: correct only the account node
        if let existingDerivationPath = derivationPath {
            let derivationIndexAwarePath = derivationPathHelper.makeDerivationPath(
                from: existingDerivationPath,
                forAccountWithIndex: derivationInfo.derivationIndex
            )

            return makeTokenItem(from: tokenItem, with: derivationIndexAwarePath)
        }

        guard let derivationStyle = derivationInfo.derivationStyle else {
            return tokenItem
        }

        // No derivation: compute from blockchain's default
        let originalDerivationPath = blockchain.derivationPath(for: derivationStyle)
        let accountAwareDerivationPath = originalDerivationPath.map { path in
            return derivationPathHelper.makeDerivationPath(from: path, forAccountWithIndex: derivationInfo.derivationIndex)
        }

        return makeTokenItem(from: tokenItem, with: accountAwareDerivationPath)
    }

    private func makeTokenItem(from tokenItem: TokenItem, with derivationPath: DerivationPath?) -> TokenItem {
        let blockchainNetwork = BlockchainNetwork(tokenItem.blockchain, derivationPath: derivationPath)

        switch tokenItem {
        case .token(let token, _):
            return .token(token, blockchainNetwork)
        case .blockchain:
            return .blockchain(blockchainNetwork)
        }
    }

    private func addInternal(_ tokenItems: [TokenItem], using updater: UserTokensRepositoryBatchUpdater) throws {
        let tokenItemsToAdd = try tokenItems.flatMap { tokenItem in
            try validateDerivation(for: tokenItem)

            if tokenItem.isBlockchain {
                return [tokenItem]
            }

            let networkTokenItem = TokenItem.blockchain(tokenItem.blockchainNetwork)
            try validateDerivation(for: networkTokenItem)

            if !userTokens.contains(networkTokenItem), !tokenItems.contains(networkTokenItem) {
                return [networkTokenItem, tokenItem]
            }

            return [tokenItem]
        }

        updater.append(tokenItemsToAdd)
    }

    private func removeInternal(_ tokenItems: [TokenItem], using updater: UserTokensRepositoryBatchUpdater) {
        for tokenItem in tokenItems where canRemove(tokenItem) {
            updater.remove(tokenItem)
        }
    }

    private func loadSwapAvailabilityStateIfNeeded(forceReload: Bool) {
        guard shouldLoadExpressAvailability else {
            return
        }

        let storedEntries = userTokensRepository.cryptoAccount.tokens
        let tokenItems = StoredEntryConverter.convertToTokenItems(storedEntries)

        expressAvailabilityProvider.updateExpressAvailability(
            for: tokenItems,
            forceReload: forceReload,
            userWalletId: userWalletId.stringValue
        )
    }

    private func validateDerivation(for tokenItem: TokenItem) throws {
        let blockchain = tokenItem.blockchain
        let derivationPath = tokenItem.blockchainNetwork.derivationPath

        if let derivationPath, blockchain.curve == .ed25519_slip0010, derivationPath.nodes.contains(where: { !$0.isHardened }) {
            throw TangemSdkError.nonHardenedDerivationNotSupported
        }

        // Some blockchains do not support any derivations other than the default one (for the main account)
        if let derivationPath,
           let accountDerivationNode = AccountDerivationPathHelper(blockchain: blockchain).extractAccountDerivationNode(from: derivationPath),
           !AccountModelUtils.isMainAccount(accountDerivationNode.rawIndex),
           !blockchain.curve.supportsDerivation {
            throw Error.derivationNotSupported(tokenName: tokenItem.name)
        }

        // Token items with custom derivations can be added to the main account as is
        if isMainAccountManager {
            return
        }

        let derivationPathHelper = AccountDerivationPathHelper(blockchain: tokenItem.blockchain)

        guard let derivationNode = derivationPathHelper.extractAccountDerivationNode(from: derivationPath) else {
            throw Error.derivationPathNotFound(tokenName: tokenItem.name)
        }

        let expectedDerivationIndex = UInt32(derivationInfo.derivationIndex)
        let actualDerivationIndex = derivationNode.rawIndex

        if actualDerivationIndex != expectedDerivationIndex {
            throw Error.accountDerivationNodeMismatch(
                expected: expectedDerivationIndex,
                actual: actualDerivationIndex,
                tokenName: tokenItem.name
            )
        }
    }

    private func handleUserTokensSync() {
        loadSwapAvailabilityStateIfNeeded(forceReload: true)
        walletModelsManager?.updateAll(silent: false) { [weak self] in
            self?.handleWalletModelsUpdate()
        }
    }

    private func handleWalletModelsUpdate() {
        let completions = pendingUserTokensSyncCompletions
        pendingUserTokensSyncCompletions.removeAll()
        completions.forEach { $0() }
    }

    private static func reorderedTokens(
        tokens: [StoredCryptoAccount.Token],
        walletModelIds: [WalletModelId.ID]
    ) -> [StoredCryptoAccount.Token] {
        let existingTokensKeyedByIds = tokens.keyedFirst(by: \.walletModelId?.id)
        var reorderedTokens: [StoredCryptoAccount.Token] = []
        // Reversing the list of wallet model ids to get an O(1) pop operation
        var reorderedWalletModelIds = Array(walletModelIds.reversed())

        // Sorting the list of tokens according to the new order of wallet model ids
        // while maintaining the order of unsupported tokens, i.e. performing a stable sort
        for token in tokens {
            // Unsupported network and/or token
            guard token.walletModelId != nil else {
                reorderedTokens.append(token)
                continue
            }

            guard let reorderedWalletModelId = reorderedWalletModelIds.popLast() else {
                // There may be tokens without derivation and thus without a wallet model,
                // so we just append them, preserving the order
                reorderedTokens.append(token)
                continue
            }

            guard let reorderedToken = existingTokensKeyedByIds[reorderedWalletModelId] else {
                assertionFailure("Inconsistency detected: token with id \(reorderedWalletModelId) not found")
                continue
            }

            reorderedTokens.append(reorderedToken)
        }

        return reorderedTokens
    }
}

// MARK: - UserTokensManager protocol conformance

extension AccountsAwareUserTokensManager: UserTokensManager {
    var initializedPublisher: AnyPublisher<Bool, Never> {
        // [REDACTED_TODO_COMMENT]
        preconditionFailure("Not used with accounts")
    }

    var userTokens: [TokenItem] {
        userTokensRepository
            .cryptoAccount
            .tokens
            .compactMap { $0.toTokenItem() }
    }

    var userTokensPublisher: AnyPublisher<[TokenItem], Never> {
        userTokensRepository
            .cryptoAccountPublisher
            .map { $0.tokens.compactMap { $0.toTokenItem() } }
            .eraseToAnyPublisher()
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

    func addTokenItemPrecondition(_ tokenItem: TokenItem) throws {
        guard hardwareLimitationsUtil.canAdd(tokenItem) else {
            throw Error.failedSupportedLongHashesTokens(blockchainDisplayName: tokenItem.blockchain.displayName)
        }

        if !existingCurves.contains(tokenItem.blockchain.curve) {
            throw Error.failedSupportedCurve(blockchainDisplayName: tokenItem.blockchain.displayName)
        }

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
            try userTokensRepository.performBatchUpdates { updater in
                try addInternal(tokenItems, using: updater)
            }
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

        userTokensRepository.performBatchUpdates { updater in
            removeInternal([tokenItem], using: updater)
        }
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

        try userTokensRepository.performBatchUpdates { updater in
            removeInternal(itemsToRemove, using: updater)
            try addInternal(itemsToAdd, using: updater)
            loadSwapAvailabilityStateIfNeeded(forceReload: true)
        }
    }

    func sync(completion: @escaping () -> Void) {
        defer {
            pendingUserTokensSyncCompletions.append(completion)
        }

        // Initiate a new update only if there is no ongoing update (i.e. `pendingUserTokensSyncCompletions` is empty)
        guard pendingUserTokensSyncCompletions.isEmpty else {
            return
        }

        userTokensRepository.updateLocalRepositoryFromServer { [weak self] _ in
            self?.handleUserTokensSync()
        }
    }
}

// MARK: - UserTokensReordering protocol conformance

extension AccountsAwareUserTokensManager: UserTokensReordering {
    var orderedWalletModelIds: AnyPublisher<[WalletModelId.ID], Never> {
        return userTokensRepository
            .cryptoAccountPublisher
            .map { $0.tokens.compactMap(\.walletModelId?.id) }
            .eraseToAnyPublisher()
    }

    var groupingOption: UserTokensReorderingOptions.Grouping {
        let converter = UserTokensReorderingOptionsConverter()
        return converter.convert(userTokensRepository.cryptoAccount.grouping)
    }

    var sortingOption: UserTokensReorderingOptions.Sorting {
        let converter = UserTokensReorderingOptionsConverter()
        return converter.convert(userTokensRepository.cryptoAccount.sorting)
    }

    var groupingOptionPublisher: AnyPublisher<UserTokensReorderingOptions.Grouping, Never> {
        let converter = UserTokensReorderingOptionsConverter()
        return userTokensRepository
            .cryptoAccountPublisher
            .map { converter.convert($0.grouping) }
            .eraseToAnyPublisher()
    }

    var sortingOptionPublisher: AnyPublisher<UserTokensReorderingOptions.Sorting, Never> {
        let converter = UserTokensReorderingOptionsConverter()
        return userTokensRepository
            .cryptoAccountPublisher
            .map { converter.convert($0.sorting) }
            .eraseToAnyPublisher()
    }

    func reorder(_ actions: [UserTokensReorderingAction], source: UserTokensReorderingSource) -> AnyPublisher<Void, Never> {
        if actions.isEmpty {
            return .just
        }

        return Deferred { [userTokensRepository = self.userTokensRepository] in
            Future { promise in
                let converter = UserTokensReorderingOptionsConverter()
                let existingAccount = userTokensRepository.cryptoAccount
                var tokens = existingAccount.tokens
                var grouping = existingAccount.grouping
                var sorting = existingAccount.sorting

                for action in actions {
                    switch action {
                    case .setGroupingOption(let option):
                        grouping = converter.convert(option)
                    case .setSortingOption(let option):
                        sorting = converter.convert(option)
                    case .reorder(let reorderedWalletModelIds):
                        let reorderedTokens = Self.reorderedTokens(tokens: tokens, walletModelIds: reorderedWalletModelIds)
                        // [REDACTED_TODO_COMMENT]
                        if reorderedTokens.count == tokens.count {
                            tokens = reorderedTokens
                        }
                    }
                }

                let updateRequest = UserTokensRepositoryUpdateRequest(
                    tokens: tokens,
                    grouping: grouping,
                    sorting: sorting
                )

                promise(.success((updateRequest, existingAccount)))
            }
            .filter { input in
                let (updateRequest, existingAccount) = input
                return updateRequest.tokens != existingAccount.tokens
                    || updateRequest.grouping != existingAccount.grouping
                    || updateRequest.sorting != existingAccount.sorting
            }
            .withWeakCaptureOf(self)
            .handleEvents(receiveOutput: { input in
                // [REDACTED_TODO_COMMENT]
                /*
                 let (userTokensManager, (editedList, existingList)) = input
                 let logger = UserTokensReorderingLogger(walletModels: userTokensManager.walletModelsManager.walletModels)
                 logger.logReorder(existingList: existingList, editedList: editedList, source: source)
                  */
            })
            .receive(on: DispatchQueue.main)
            .map { input in
                let (userTokensManager, (updateRequest, _)) = input
                userTokensManager.userTokensRepository.performBatchUpdates { updater in
                    updater.update(updateRequest)
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - Auxiliary types

extension AccountsAwareUserTokensManager {
    struct DerivationInfo {
        let derivationIndex: Int
        let derivationStyle: DerivationStyle?
    }

    enum Error: LocalizedError {
        case addressNotFound
        case derivationNotSupported(tokenName: String)
        case derivationPathNotFound(tokenName: String)
        case accountDerivationNodeMismatch(expected: UInt32, actual: UInt32, tokenName: String)
        case failedSupportedLongHashesTokens(blockchainDisplayName: String)
        case failedSupportedCurve(blockchainDisplayName: String)

        var errorDescription: String? {
            switch self {
            case .failedSupportedLongHashesTokens(let blockchainDisplayName):
                return Localization.alertManageTokensUnsupportedMessage(blockchainDisplayName)
            case .failedSupportedCurve(let blockchainDisplayName):
                return Localization.alertManageTokensUnsupportedCurveMessage(blockchainDisplayName)
            case .addressNotFound,
                 .derivationNotSupported,
                 .derivationPathNotFound,
                 .accountDerivationNodeMismatch:
                // [REDACTED_TODO_COMMENT]
                return Localization.genericErrorCode(errorCode)
            }
        }
    }
}
