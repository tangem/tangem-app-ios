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

// [REDACTED_TODO_COMMENT]
private extension StoredCryptoAccount.Token.BlockchainNetworkContainer {
    var knownValue: BlockchainNetwork? {
        switch self {
        case .known(let blockchainNetwork):
            return blockchainNetwork
        case .unknown:
            return nil
        }
    }
}

// [REDACTED_TODO_COMMENT]
private extension StoredCryptoAccount.Token {
    func isEqualTo(_ bsdkToken: Token) -> Bool {
        // Matches the `Equatable` implementation of the `BlockchainSdk.Token`
        return contractAddress == bsdkToken.contractAddress
    }

    func toBSDKToken() -> Token? {
        guard let contractAddress else {
            return nil
        }

        return Token(
            name: name,
            symbol: symbol,
            contractAddress: contractAddress,
            decimalCount: decimalCount,
            id: id,
            metadata: .fungibleTokenMetadata // By definition, in the domain layer we're dealing only with fungible tokens
        )
    }

    var walletModelId: WalletModelId? {
        guard let blockchainNetwork = blockchainNetwork.knownValue else {
            return nil
        }

        if let token = toBSDKToken() {
            return WalletModelId(tokenItem: .token(token, blockchainNetwork))
        }

        return WalletModelId(tokenItem: .blockchain(blockchainNetwork))
    }
}

// [REDACTED_TODO_COMMENT]
struct _StorageEntryConverter {
    func convertToTokenItems(_ entries: [StoredCryptoAccount.Token]) -> [TokenItem] {
        entries.compactMap { entry -> TokenItem? in
            let blockchainNetwork: BlockchainNetwork
            switch entry.blockchainNetwork {
            case .known(let _blockchainNetwork):
                blockchainNetwork = _blockchainNetwork
            case .unknown:
                // Unsupported, filtering it out
                return nil
            }

            guard let contractAddress = entry.contractAddress else {
                return .blockchain(blockchainNetwork)
            }

            let token = Token(
                name: entry.name,
                symbol: entry.symbol,
                contractAddress: contractAddress,
                decimalCount: entry.decimalCount,
                id: entry.id
            )
            return .token(token, blockchainNetwork)
        }
    }
}

// [REDACTED_TODO_COMMENT]
protocol _UserTokenListManager {
    var cryptoAccountPublisher: AnyPublisher<StoredCryptoAccount, Never> { get }
    var cryptoAccount: StoredCryptoAccount { get }

    func update(_ type: UserTokenListUpdateType, shouldUpload: Bool)
    func update(with info: StoredCryptoAccountUpdateInfo)
    func updateLocalRepositoryFromServer(_ completion: @escaping (Result<Void, any Error>) -> Void)
    func upload()
}

// [REDACTED_TODO_COMMENT]
struct StoredCryptoAccountUpdateInfo {
    let tokens: [StoredCryptoAccount.Token]
    let grouping: StoredCryptoAccount.Grouping
    let sorting: StoredCryptoAccount.Sorting
}

/// Copy-paste of `CommonUserTokensManager`, but with accounts support.
final class AccountsAwareUserTokensManager {
    @Injected(\.expressAvailabilityProvider) private var expressAvailabilityProvider: ExpressAvailabilityProvider

    weak var keysDerivingProvider: KeysDerivingProvider?

    private let userWalletId: UserWalletId
    private let userTokenListManager: _UserTokenListManager
    private let walletModelsManager: WalletModelsManager
    private let derivationInfo: DerivationInfo
    private let existingCurves: [EllipticCurve]
    private let shouldLoadExpressAvailability: Bool
    private let areLongHashesSupported: Bool
    private var pendingUserTokensSyncCompletions: [() -> Void] = []

    private var isMainAccountManager: Bool {
        AccountModelUtils.isMainAccount(derivationInfo.derivationIndex)
    }

    init(
        userWalletId: UserWalletId,
        userTokenListManager: _UserTokenListManager,
        walletModelsManager: WalletModelsManager,
        derivationInfo: DerivationInfo,
        existingCurves: [EllipticCurve],
        shouldLoadExpressAvailability: Bool,
        areLongHashesSupported: Bool
    ) {
        self.userWalletId = userWalletId
        self.userTokenListManager = userTokenListManager
        self.walletModelsManager = walletModelsManager
        self.derivationInfo = derivationInfo
        self.existingCurves = existingCurves
        self.shouldLoadExpressAvailability = shouldLoadExpressAvailability
        self.areLongHashesSupported = areLongHashesSupported
    }

    private func withBlockchainNetwork(_ tokenItem: TokenItem) -> TokenItem {
        let blockchain = tokenItem.blockchain
        let derivationPathHelper = AccountDerivationPathHelper(blockchain: blockchain)

        // In case when a token item already contains derivation such token item can be added to the main account as is
        if isMainAccountManager {
            return makeTokenItem(from: tokenItem, with: tokenItem.blockchainNetwork.derivationPath)
        }

        guard let derivationStyle = derivationInfo.derivationStyle else {
            return tokenItem
        }

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

        let converter = _StorageEntryConverter()
        let tokenItems = converter.convertToTokenItems(userTokenListManager.cryptoAccount.tokens)

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
        walletModelsManager.updateAll(silent: false) { [weak self] in
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
                let walletModelsCount = walletModelIds.count
                let allTokensCount = tokens.count
                let unsupportedTokensCount = tokens.count { $0.walletModelId == nil }
                assertionFailure(
                    """
                    Inconsistency detected: mismatched number of wallet models (\(walletModelsCount)) and the \
                    number of tokens (\(allTokensCount)) minus the number of unsupported tokens (\(unsupportedTokensCount))
                    """
                )
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
    var derivationManager: DerivationManager? {
        derivationInfo.derivationManager
    }

    func needsCardDerivation(itemsToRemove: [TokenItem], itemsToAdd: [TokenItem]) -> Bool {
        guard let derivationManager, let keysDerivingProvider else {
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
            networksToAdd: networksToAdd,
            interactor: keysDerivingProvider.keysDerivingInteractor
        )
    }

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

    func contains(_ tokenItem: TokenItem, derivationInsensitive: Bool) -> Bool {
        let tokenItem = withBlockchainNetwork(tokenItem)
        let tokens = userTokenListManager.cryptoAccount.tokens

        let filteredTokens = derivationInsensitive
            ? tokens.filter { $0.blockchainNetwork.knownValue?.blockchain.networkId == tokenItem.blockchainNetwork.blockchain.networkId }
            : tokens.filter { $0.blockchainNetwork.knownValue == tokenItem.blockchainNetwork }

        switch tokenItem {
        case .blockchain:
            return filteredTokens.isNotEmpty
        case .token(let token, _):
            return filteredTokens.contains { $0.isEqualTo(token) }
        }
    }

    func addTokenItemPrecondition(_ tokenItem: TokenItem) throws {
        if AppUtils().hasLongHashesForSend(tokenItem), !areLongHashesSupported {
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
            throw Error.addressNotFound
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

        let existingTokens = userTokenListManager
            .cryptoAccount
            .tokens
            .filter { $0.blockchainNetwork.knownValue == tokenItem.blockchainNetwork }
            .compactMap { $0.toBSDKToken() }

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

extension AccountsAwareUserTokensManager: UserTokensReordering {
    var orderedWalletModelIds: AnyPublisher<[WalletModelId.ID], Never> {
        return userTokenListManager
            .cryptoAccountPublisher
            .map { $0.tokens.compactMap(\.walletModelId?.id) }
            .eraseToAnyPublisher()
    }

    var groupingOption: AnyPublisher<UserTokensReorderingOptions.Grouping, Never> {
        let converter = UserTokensReorderingOptionsConverter()
        return userTokenListManager
            .cryptoAccountPublisher
            .map { converter.convert($0.grouping) }
            .eraseToAnyPublisher()
    }

    var sortingOption: AnyPublisher<UserTokensReorderingOptions.Sorting, Never> {
        let converter = UserTokensReorderingOptionsConverter()
        return userTokenListManager
            .cryptoAccountPublisher
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
                let existingAccount = userTokenListManager.cryptoAccount
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

                let updateInfo = StoredCryptoAccountUpdateInfo(
                    tokens: tokens,
                    grouping: grouping,
                    sorting: sorting
                )

                promise(.success((updateInfo, existingAccount)))
            }
            .filter { input in
                let (updateInfo, existingAccount) = input
                return updateInfo.tokens != existingAccount.tokens
                    || updateInfo.grouping != existingAccount.grouping
                    || updateInfo.sorting != existingAccount.sorting
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
                let (userTokensManager, (updateInfo, _)) = input
                userTokensManager.userTokenListManager.update(with: updateInfo)
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
        let derivationManager: DerivationManager?
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
