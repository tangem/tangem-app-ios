//
//  CommonWalletTokenAutoSyncOrchestrator.swift
//  Tangem
//
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import TangemFoundation
import BlockchainSdk

final class CommonWalletTokenAutoSyncOrchestrator: WalletTokenAutoSyncInteractor {
    private let addressResolver: WalletAddressResolver
    private let tokenBalanceClient: MoralisTokenBalanceClient
    private let tangemApiService: TangemApiService
    private let syncStateActor: WalletTokenAutoSyncStateActor
    private let progressService: WalletTokenAutoSyncProgressService

    private let coinMapper = CoinsCatalogMapper()
    private var waitForTokenListTask: Task<Void, Error>?

    init(
        addressResolver: WalletAddressResolver,
        tokenBalanceClient: MoralisTokenBalanceClient,
        tangemApiService: TangemApiService,
        syncStateActor: WalletTokenAutoSyncStateActor,
        progressService: WalletTokenAutoSyncProgressService
    ) {
        self.addressResolver = addressResolver
        self.tokenBalanceClient = tokenBalanceClient
        self.tangemApiService = tangemApiService
        self.syncStateActor = syncStateActor
        self.progressService = progressService
    }

    func startIfPossible(userWalletModel: UserWalletModel, keyInfos: [KeyInfo]) async throws {
        let userWalletId = userWalletModel.userWalletId
        let stateActor = syncStateActor
        try await stateActor.tryRegister(userWalletId: userWalletId)

        Task.detached(priority: .utility) { [weak self] in
            do {
                if let self {
                    try await performSync(userWalletModel: userWalletModel, keyInfos: keyInfos)
                }
            } catch {
                AppLogger.tag("CommonWalletTokenAutoSyncOrchestrator").error("Sync failed", error: error)
            }
            await stateActor.unregister(userWalletId: userWalletId)
        }
    }
}

// MARK: - Private

private extension CommonWalletTokenAutoSyncOrchestrator {
    func performSync(userWalletModel: UserWalletModel, keyInfos: [KeyInfo]) async throws {
        let userWalletId = userWalletModel.userWalletId

        await progressService.add(userWalletId: userWalletId)

        var allTokens: [TokenItem] = []

        let totalNetworks = MoralisSupportedBlockchains.all.count

        for (index, blockchain) in MoralisSupportedBlockchains.all.enumerated() {
            if Task.isCancelled { break }

            do {
                let pair = try addressResolver.resolveAddress(for: blockchain, keyInfos: keyInfos)

                let balances = try await tokenBalanceClient.getTokenBalances(
                    network: pair.blockchainNetwork.blockchain,
                    address: pair.address
                )

                let nonZeroBalances = balances.filter { $0.amount > 0 }

                let contractAddressToCoinId = await fetchContractAddressToCoinIdMap(
                    balances: nonZeroBalances,
                    blockchain: pair.blockchainNetwork.blockchain
                )
                let tokenItems = mapToTokenItems(
                    balances: nonZeroBalances,
                    blockchainNetwork: pair.blockchainNetwork,
                    contractAddressToCoinId: contractAddressToCoinId
                )
                allTokens.append(contentsOf: tokenItems)
            } catch {
                AppLogger.tag("WalletTokenAutoSync").debug("Skip \(blockchain.displayName): \(error)")
            }

            let percent = Int((Double(index + 1) / Double(totalNetworks)) * 100)
            await progressService.reportProgress(userWalletId: userWalletId, percent: min(percent, 99))
        }

        if !allTokens.isEmpty {
            await syncDiscoveredTokensWithAccounts(
                discoveredTokens: allTokens,
                accountModelsManager: userWalletModel.accountModelsManager
            )
        }

        await progressService.reportProgress(userWalletId: userWalletId, percent: 100)
        await progressService.remove(userWalletId: userWalletId)
    }

    func fetchContractAddressToCoinIdMap(
        balances: [MoralisTokenBalance],
        blockchain: Blockchain
    ) async -> [String: String] {
        let contractAddresses = balances
            .filter { !$0.isNativeToken }
            .compactMap { $0.contractAddress }

        guard !contractAddresses.isEmpty else {
            return [:]
        }

        do {
            let request = CoinsList.Request(
                supportedBlockchains: [blockchain],
                contractAddresses: contractAddresses,
                limit: contractAddresses.count,
                active: true
            )
            let response = try await tangemApiService.loadCoins(requestModel: request)
            let mapResult = coinMapper.buildContractAddressToCoinIdMap(from: response)
            return mapResult
        } catch {
            AppLogger.tag("WalletTokenAutoSync").debug("Coins catalog lookup failed: \(error)")
            return [:]
        }
    }

    func mapToTokenItems(
        balances: [MoralisTokenBalance],
        blockchainNetwork: BlockchainNetwork,
        contractAddressToCoinId: [String: String]
    ) -> [TokenItem] {
        balances.compactMap { balance in
            if balance.isNativeToken {
                return .blockchain(blockchainNetwork)
            }
            guard let contractAddress = balance.contractAddress else {
                return nil
            }
            let currencyId = contractAddressToCoinId[contractAddress.lowercased()]
            let token = Token(
                name: balance.name,
                symbol: balance.symbol,
                contractAddress: contractAddress,
                decimalCount: balance.decimals,
                id: currencyId
            )
            return .token(token, blockchainNetwork)
        }
    }

    func syncDiscoveredTokensWithAccounts(
        discoveredTokens: [TokenItem],
        accountModelsManager: AccountModelsManager,
        attempt: Int = 0
    ) async {
        do {
            try await waitForTokenListReady(accountModelsManager: accountModelsManager)

            addNewTokensToMainAccount(
                discoveredTokens: discoveredTokens,
                accountModelsManager: accountModelsManager
            )
        } catch {
            guard attempt < Constants.maxSyncRetries, !Task.isCancelled else {
                AppLogger.tag("WalletTokenAutoSync").error("Failed to sync discovered tokens after \(attempt) attempts", error: error)
                return
            }

            AppLogger.tag("WalletTokenAutoSync").debug("Token list not ready, retry \(attempt + 1)/\(Constants.maxSyncRetries)")

            await syncDiscoveredTokensWithAccounts(
                discoveredTokens: discoveredTokens,
                accountModelsManager: accountModelsManager,
                attempt: attempt + 1
            )
        }
    }

    func waitForTokenListReady(accountModelsManager: AccountModelsManager) async throws {
        try await accountModelsManager
            .cryptoAccountModelsPublisher
            .setFailureType(to: WalletTokenAutoSyncError.self)
            .flatMapLatest { cryptoAccountModels -> AnyPublisher<Void, WalletTokenAutoSyncError> in
                guard cryptoAccountModels.isNotEmpty else {
                    return Fail(error: .userTokenListNotReady).eraseToAnyPublisher()
                }

                return cryptoAccountModels
                    .map { $0.userTokensManager.userTokensPublisher }
                    .combineLatest()
                    .map { _ in () }
                    .setFailureType(to: WalletTokenAutoSyncError.self)
                    .eraseToAnyPublisher()
            }
            .timeout(
                .seconds(Constants.syncTimeoutSeconds),
                scheduler: DispatchQueue.main,
                customError: { .userTokenListNotReady }
            )
            .async()
    }

    func addNewTokensToMainAccount(
        discoveredTokens: [TokenItem],
        accountModelsManager: AccountModelsManager
    ) {
        guard let mainAccount = accountModelsManager.cryptoAccountModels.first(where: { $0.isMainAccount }) else {
            AppLogger.tag("WalletTokenAutoSync").debug("No main crypto account found, skipping token persistence")
            return
        }

        let newTokens = discoveredTokens.filter { token in
            // [REDACTED_TODO_COMMENT]
            token.blockchain == .polygon(testnet: false)
                && !mainAccount.userTokensManager.contains(token, derivationInsensitive: false)
        }

        guard newTokens.isNotEmpty else {
            AppLogger.tag("WalletTokenAutoSync").debug("No new tokens to add, all already present")
            return
        }

        do {
            try mainAccount.userTokensManager.update(itemsToRemove: [], itemsToAdd: newTokens)
            AppLogger.tag("WalletTokenAutoSync").debug("Added \(newTokens.count) new tokens to main account")
        } catch {
            AppLogger.tag("WalletTokenAutoSync").error("Failed to add tokens to main account", error: error)
        }
    }
}

private extension CommonWalletTokenAutoSyncOrchestrator {
    enum Constants {
        static let maxSyncRetries = 5
        static let syncTimeoutSeconds = 3
    }
}
