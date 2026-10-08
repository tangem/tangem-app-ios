//
//  CommonTransactionHistoryAuxDataRepositoryTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
import TangemExpress
import TangemStaking
@testable import Tangem

@Suite("CommonTransactionHistoryAuxDataRepository")
struct CommonTransactionHistoryAuxDataRepositoryTests {
    @Test(arguments: [false, true])
    func announcesCacheRestoredFromStorage(subscribesAfterRestore: Bool) async throws {
        let tokenItem = TokenItem.blockchain(BlockchainNetwork(.polygon(testnet: false), derivationPath: nil))
        let currency = tokenItem.normalizedExpressCurrency
        let storage = GatedAuxDataStorage(cryptoCurrencies: [tokenItem])
        let repository = CommonTransactionHistoryAuxDataRepository(
            cachingExpressAPIProviderFactory: CachingExpressAPIProviderFactory { userWalletId, refcode in
                ExpressAPIProviderFactory().makeExpressAPIProvider(userId: userWalletId, refcode: refcode)
            },
            storage: storage
        )
        let cachedCryptoCurrency: (ExpressCurrency) -> TokenItem? = repository.cryptoCurrency(for:)

        #expect(cachedCryptoCurrency(currency) == nil)

        if subscribesAfterRestore {
            await storage.open()
            for _ in 0 ..< 40 where cachedCryptoCurrency(currency) == nil {
                try await Task.sleep(for: .milliseconds(50))
            }
        }

        let announcedRestoredCache = Task {
            let cachedCryptoCurrency: (ExpressCurrency) -> TokenItem? = repository.cryptoCurrency(for:)
            for await _ in repository.didLoadAuxData where cachedCryptoCurrency(currency) == tokenItem {
                return true
            }
            return false
        }

        await storage.open()

        let timeout = Task {
            try await Task.sleep(for: .seconds(2))
            announcedRestoredCache.cancel()
        }
        let didAnnounce = await announcedRestoredCache.value
        timeout.cancel()

        #expect(didAnnounce, "No subscriber event follows the cache restored from storage, so a merge done before it never resolves the currencies")
    }
}

// MARK: - Stubs

private actor GatedAuxDataStorage: TransactionHistoryAuxDataStorage {
    private let storedCryptoCurrencies: [TokenItem]
    private var isOpen = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    init(cryptoCurrencies: [TokenItem]) {
        storedCryptoCurrencies = cryptoCurrencies
    }

    func open() {
        isOpen = true
        waiters.forEach { $0.resume() }
        waiters.removeAll()
    }

    func providers() async throws -> [TransactionHistoryAuxDataCachedValue<ExpressProvider>] {
        if !isOpen {
            await withCheckedContinuation { waiters.append($0) }
        }

        return []
    }

    func saveProviders(_ providers: [ExpressProvider]) async throws {}

    func fiatCurrencies() async throws -> [TransactionHistoryAuxDataCachedValue<OnrampFiatCurrency>] { [] }

    func saveFiatCurrencies(_ currencies: [OnrampFiatCurrency]) async throws {}

    func cryptoCurrencies() async throws -> [TransactionHistoryAuxDataCachedValue<TokenItem>] {
        storedCryptoCurrencies.map { TransactionHistoryAuxDataCachedValue(value: $0, updatedAt: Date()) }
    }

    func saveCryptoCurrencies(_ tokenItems: [TokenItem]) async throws {}

    func stakingTargets() async throws -> [TransactionHistoryAuxDataCachedValue<StakingTargetSummary>] { [] }

    func saveStakingTargets(_ targets: [StakingTargetSummary]) async throws {}
}
