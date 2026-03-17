//
//  CommonWalletTokenAutoSyncOrchestrator.swift
//  Tangem
//
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import BlockchainSdk

final class CommonWalletTokenAutoSyncOrchestrator: WalletTokenAutoSyncInteractor {
    private let addressResolver: WalletAddressResolver
    private let tokenBalanceClient: MoralisTokenBalanceClient
    private let tangemApiService: TangemApiService
    private let syncStateActor: WalletTokenAutoSyncStateActor
    private let progressService: WalletTokenAutoSyncProgressService

    private let coinMapper = CoinsCatalogMapper()

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

                // [REDACTED_TODO_COMMENT]
                // Set guard for filter non zero token balance

                let contractAddressToCoinId = await fetchContractAddressToCoinIdMap(
                    balances: balances,
                    blockchain: pair.blockchainNetwork.blockchain
                )
                let tokenItems = mapToTokenItems(
                    balances: balances,
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
            persistDiscoveredTokens(userWalletId: userWalletId, tokens: allTokens)
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

    func persistDiscoveredTokens(userWalletId: UserWalletId, tokens: [TokenItem]) {
        // [REDACTED_TODO_COMMENT]
        _ = userWalletId
        _ = tokens
    }
}
