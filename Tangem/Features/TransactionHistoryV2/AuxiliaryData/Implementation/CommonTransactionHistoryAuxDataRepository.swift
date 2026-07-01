//
//  CommonTransactionHistoryAuxDataRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemExpress
import TangemFoundation

actor CommonTransactionHistoryAuxDataRepository {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    private var cache = Cache()

    private nonisolated let syncCache = OSAllocatedUnfairLock(initialState: Cache())

    private var subscribers = AsyncStream<Void>.MulticastSubscribers<UUID>()

    private var inFlightProvidersLoadTask: Task<Void, Never>?
    private var inFlightFiatCurrenciesLoadTask: Task<Void, Never>?

    private var pendingCoins: [String: TokenItem] = [:]
    private var inFlightCoinKeys: Set<String> = []
    private var coinWaiters: [String: [CheckedContinuation<Void, Never>]] = [:]
    private var coinsDebounceTask: Task<Void, Never>?

    private let cachingExpressAPIProviderFactory: CachingExpressAPIProviderFactory

    private let makeStorage: () async -> UserDefaultsTransactionHistoryAuxDataStorage

    init(cachingExpressAPIProviderFactory: CachingExpressAPIProviderFactory) {
        self.cachingExpressAPIProviderFactory = cachingExpressAPIProviderFactory

        makeStorage = { @MainActor in
            UserDefaultsTransactionHistoryAuxDataStorage()
        }

        Task { [weak self] in
            await self?.loadFromStorage()
        }
    }
}

// MARK: - TransactionHistoryAuxDataRepository

extension CommonTransactionHistoryAuxDataRepository: TransactionHistoryAuxDataRepository {
    nonisolated var didLoadAuxData: AsyncStream<Void> {
        return .multicast(
            with: self,
            onSubscribe: { repository, id, continuation in
                repository.subscribers.subscribe(id: id, continuation: continuation)
            },
            onUnsubscribe: { repository, id in
                repository.subscribers.unsubscribe(id: id)
            }
        )
    }

    // MARK: Providers

    nonisolated func provider(id: ExpressProvider.Id) -> ExpressProvider? {
        let cached = syncCache { $0.providers[id] }

        if cached == nil {
            Task { [self] in
                await loadProvidersInfoIfNeeded()
            }
        }

        return cached
    }

    func provider(id: ExpressProvider.Id) async -> ExpressProvider? {
        if let cached = cache.providers[id] {
            return cached
        }

        await loadProvidersInfoIfNeeded()

        return cache.providers[id]
    }

    // MARK: Fiat currencies

    nonisolated func fiatCurrency(for asset: OnrampHistoryFiatAsset) -> OnrampFiatCurrency? {
        let cached = syncCache { $0.fiatCurrencies[asset.currencyCode] }

        if cached == nil {
            Task { [self] in
                await ensureCurrenciesLoaded()
            }
        }

        return cached
    }

    func fiatCurrency(for asset: OnrampHistoryFiatAsset) async -> OnrampFiatCurrency? {
        if let cached = cache.fiatCurrencies[asset.currencyCode] {
            return cached
        }

        await ensureCurrenciesLoaded()

        return cache.fiatCurrencies[asset.currencyCode]
    }

    // MARK: Coins

    nonisolated func coin(for tokenItem: TokenItem) -> CoinsList.Coin? {
        let key = Self.makeCoinKey(for: tokenItem)
        let cached = syncCache { $0.coins[key] }

        if cached == nil {
            Task { [self] in
                await ensureCoinLoaded(tokenItem, key: key, waitForResult: false)
            }
        }

        return cached
    }

    func coin(for tokenItem: TokenItem) async -> CoinsList.Coin? {
        let key = Self.makeCoinKey(for: tokenItem)

        if let cached = cache.coins[key] {
            return cached
        }

        await ensureCoinLoaded(tokenItem, key: key, waitForResult: true)

        return cache.coins[key]
    }
}

// MARK: - Providers / currencies loading

private extension CommonTransactionHistoryAuxDataRepository {
    func makeExpressAPIProvider() -> ExpressAPIProvider? {
        guard let model = userWalletRepository.models.first else {
            return nil
        }

        return cachingExpressAPIProviderFactory.provider(
            for: model.userWalletId.stringValue,
            refcode: model.refcodeProvider?.getRefcode()
        )
    }

    func loadProvidersInfoIfNeeded() async {
        if let task = inFlightProvidersLoadTask {
            return await task.value
        }

        let task = Task { [self] in
            try? await Task.sleep(for: Constants.debounce)
            await performProvidersLoad()
        }
        inFlightProvidersLoadTask = task
        await task.value
        inFlightProvidersLoadTask = nil
    }

    func performProvidersLoad() async {
        guard let expressAPIProvider = makeExpressAPIProvider() else {
            return
        }

        do {
            // The full provider set spans both branches.
            let swap = try await expressAPIProvider.providers(branch: .swap)
            let onramp = try await expressAPIProvider.providers(branch: .onramp)

            var changed = false

            for provider in swap + onramp {
                if cache.providers[provider.id] != provider {
                    cache.providers[provider.id] = provider
                    changed = true
                }
            }

            guard changed else {
                return // silent when nothing new → no re-query loop
            }

            mirrorToSyncCache()
            await persistProviders()
            subscribers.yield(())
        } catch {
            TransactionHistoryLogger.error(self, "Failed to load Express providers", error: error)
        }
    }

    func ensureCurrenciesLoaded() async {
        if let task = inFlightFiatCurrenciesLoadTask {
            await task.value

            return
        }

        let task = Task { [self] in
            try? await Task.sleep(for: Constants.debounce)
            await performCurrenciesLoad()
        }
        inFlightFiatCurrenciesLoadTask = task
        await task.value
        inFlightFiatCurrenciesLoadTask = nil
    }

    func performCurrenciesLoad() async {
        guard let expressAPIProvider = makeExpressAPIProvider() else {
            return
        }

        do {
            let loaded = try await expressAPIProvider.onrampCurrencies()

            var changed = false

            for currency in loaded {
                if cache.fiatCurrencies[currency.identity.code] != currency {
                    cache.fiatCurrencies[currency.identity.code] = currency
                    changed = true
                }
            }

            guard changed else {
                return
            }

            mirrorToSyncCache()
            await persistCurrencies()
            subscribers.yield(())
        } catch {
            TransactionHistoryLogger.error(self, "Failed to load onramp currencies", error: error)
        }
    }
}

// MARK: - Coins loading

private extension CommonTransactionHistoryAuxDataRepository {
    func ensureCoinLoaded(_ tokenItem: TokenItem, key: String, waitForResult: Bool) async {
        if cache.coins[key] != nil {
            return
        }

        if !inFlightCoinKeys.contains(key) {
            pendingCoins[key] = tokenItem
            armCoinsDebounce()
        }

        guard waitForResult else {
            return
        }

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            if cache.coins[key] != nil {
                continuation.resume()

                return
            }

            coinWaiters[key, default: []].append(continuation)
        }
    }

    func armCoinsDebounce() {
        coinsDebounceTask?.cancel()
        coinsDebounceTask = Task { [self] in
            try? await Task.sleep(for: Constants.debounce)

            guard !Task.isCancelled else {
                return
            }

            await flushPendingCoins()
        }
    }

    func flushPendingCoins() async {
        let batch = pendingCoins // claim atomically (no await above → no interleave)

        guard !batch.isEmpty else {
            return
        }

        pendingCoins.removeAll()
        inFlightCoinKeys.formUnion(batch.keys)

        await performCoinsLoad(batch)
    }

    func performCoinsLoad(_ batch: [String: TokenItem]) async {
        defer {
            inFlightCoinKeys.subtract(batch.keys)
            resumeCoinWaiters(for: Set(batch.keys)) // resume on success AND failure so callers never hang
        }

        do {
            let tokenItems = Array(batch.values)
            let request = CoinsList.Request(
                supportedBlockchains: Set(tokenItems.map(\.blockchain)),
                contractAddresses: tokenItems.compactMap(\.contractAddress).nilIfEmpty
            )
            let response = try await tangemApiService.loadCoins(requestModel: request)
            let resolved = Self.makeResolvedCoins(from: response.coins, requestedKeys: Set(batch.keys))

            var changed = false

            for (key, coin) in resolved {
                if cache.coins[key] == nil {
                    cache.coins[key] = coin
                    changed = true
                }
            }

            guard changed else {
                return
            }

            mirrorToSyncCache()
            await persistCoins()
            subscribers.yield(())
        } catch {
            TransactionHistoryLogger.error(self, "Failed to load coins", error: error)
        }
    }

    func resumeCoinWaiters(for keys: Set<String>) {
        for key in keys {
            guard let waiters = coinWaiters.removeValue(forKey: key) else {
                continue
            }

            for waiter in waiters {
                waiter.resume()
            }
        }
    }
}

// MARK: - Persistence

private extension CommonTransactionHistoryAuxDataRepository {
    func loadFromStorage() async {
        let storage = await makeStorage()
        let storedProviders = storage.providers
        let storedCurrencies = storage.fiatCurrencies
        let storedCoins = storage.coins

        for provider in storedProviders {
            cache.providers[provider.id] = provider
        }

        for currency in storedCurrencies {
            cache.fiatCurrencies[currency.identity.code] = currency
        }

        cache.coins = storedCoins

        mirrorToSyncCache()
    }

    func persistProviders() async {
        let snapshot = Array(cache.providers.values)
        let storage = await makeStorage()
        await MainActor.run {
            storage.providers = snapshot
        }
    }

    func persistCurrencies() async {
        let snapshot = Array(cache.fiatCurrencies.values)
        let storage = await makeStorage()
        await MainActor.run {
            storage.fiatCurrencies = snapshot
        }
    }

    func persistCoins() async {
        let snapshot = cache.coins
        let storage = await makeStorage()
        await MainActor.run {
            storage.coins = snapshot
        }
    }

    func mirrorToSyncCache() {
        let snapshot = cache

        syncCache { $0 = snapshot }
    }
}

// MARK: - Helpers

private extension CommonTransactionHistoryAuxDataRepository {
    struct Cache {
        var providers: [ExpressProvider.Id: ExpressProvider] = [:]
        var fiatCurrencies: [String: OnrampFiatCurrency] = [:]
        var coins: [String: CoinsList.Coin] = [:]
    }

    enum Constants {
        static let debounce: Duration = .milliseconds(300)
    }

    static func makeCoinKey(networkId: String, contractAddress: String?) -> String {
        return "\(networkId)_\(contractAddress ?? "")"
    }

    static func makeCoinKey(for tokenItem: TokenItem) -> String {
        return makeCoinKey(networkId: tokenItem.networkId, contractAddress: tokenItem.contractAddress)
    }

    /// A `Coin` carries `networks: [NetworkModel]`, so one `Coin` can satisfy several requested keys.
    static func makeResolvedCoins(from coins: [CoinsList.Coin], requestedKeys: Set<String>) -> [String: CoinsList.Coin] {
        var result: [String: CoinsList.Coin] = [:]

        for coin in coins {
            for network in coin.networks {
                let key = makeCoinKey(networkId: network.networkId, contractAddress: network.contractAddress)

                if requestedKeys.contains(key) {
                    result[key] = coin
                }
            }
        }

        return result
    }
}

// MARK: - CustomStringConvertible

extension CommonTransactionHistoryAuxDataRepository: CustomStringConvertible {
    nonisolated var description: String {
        return "CommonTransactionHistoryAuxDataRepository"
    }
}
