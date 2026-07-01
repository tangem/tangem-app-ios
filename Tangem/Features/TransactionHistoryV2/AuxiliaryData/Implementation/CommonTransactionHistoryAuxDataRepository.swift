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

    private var providers: [ExpressProvider.Id: ExpressProvider] = [:]
    private var fiatCurrencies: [String: OnrampFiatCurrency] = [:]
    private var coins: [String: CoinsList.Coin] = [:]

    private nonisolated let syncCache = OSAllocatedUnfairLock(initialState: SyncCache())

    private var subscribers = AsyncStream<Void>.MulticastSubscribers<UUID>()

    private var providersInFlight: Task<Void, Never>?
    private var currenciesInFlight: Task<Void, Never>?

    private var pendingCoins: [String: TokenItem] = [:]
    private var inFlightCoinKeys: Set<String> = []
    private var coinWaiters: [String: [CheckedContinuation<Void, Never>]] = [:]
    private var coinsDebounceTask: Task<Void, Never>?

    private let cachingExpressAPIProviderFactory: CachingExpressAPIProviderFactory

    private let makeStorage: () async -> TransactionHistoryAuxDataStorage

    init(cachingExpressAPIProviderFactory: CachingExpressAPIProviderFactory) {
        self.cachingExpressAPIProviderFactory = cachingExpressAPIProviderFactory
        makeStorage = { @MainActor in
            TransactionHistoryAuxDataStorage()
        }

        Task { [weak self] in
            await self?.hydrateFromStorage()
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
                await ensureProvidersLoaded()
            }
        }

        return cached
    }

    func provider(id: ExpressProvider.Id) async -> ExpressProvider? {
        if let cached = providers[id] {
            return cached
        }

        await ensureProvidersLoaded()

        return providers[id]
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
        if let cached = fiatCurrencies[asset.currencyCode] {
            return cached
        }

        await ensureCurrenciesLoaded()

        return fiatCurrencies[asset.currencyCode]
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

        if let cached = coins[key] {
            return cached
        }

        await ensureCoinLoaded(tokenItem, key: key, waitForResult: true)

        return coins[key]
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

    func ensureProvidersLoaded() async {
        if let task = providersInFlight {
            await task.value

            return
        }

        let task = Task { [self] in
            try? await Task.sleep(for: Constants.debounce)
            await performProvidersLoad()
        }
        providersInFlight = task
        await task.value
        providersInFlight = nil
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
                if providers[provider.id] != provider {
                    providers[provider.id] = provider
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
        if let task = currenciesInFlight {
            await task.value

            return
        }

        let task = Task { [self] in
            try? await Task.sleep(for: Constants.debounce)
            await performCurrenciesLoad()
        }
        currenciesInFlight = task
        await task.value
        currenciesInFlight = nil
    }

    func performCurrenciesLoad() async {
        guard let expressAPIProvider = makeExpressAPIProvider() else {
            return
        }

        do {
            let loaded = try await expressAPIProvider.onrampCurrencies()

            var changed = false

            for currency in loaded {
                if fiatCurrencies[currency.identity.code] != currency {
                    fiatCurrencies[currency.identity.code] = currency
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
        if coins[key] != nil {
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
            if coins[key] != nil {
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
                if coins[key] == nil {
                    coins[key] = coin
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
    func hydrateFromStorage() async {
        let storage = await makeStorage()
        let storedProviders = storage.providers
        let storedCurrencies = storage.fiatCurrencies
        let storedCoins = storage.coins

        for provider in storedProviders {
            providers[provider.id] = provider
        }

        for currency in storedCurrencies {
            fiatCurrencies[currency.identity.code] = currency
        }

        coins = storedCoins

        mirrorToSyncCache()
    }

    func persistProviders() async {
        let snapshot = Array(providers.values)
        let storage = await makeStorage()
        await MainActor.run {
            storage.providers = snapshot
        }
    }

    func persistCurrencies() async {
        let snapshot = Array(fiatCurrencies.values)
        let storage = await makeStorage()
        await MainActor.run {
            storage.fiatCurrencies = snapshot
        }
    }

    func persistCoins() async {
        let snapshot = coins
        let storage = await makeStorage()
        await MainActor.run {
            storage.coins = snapshot
        }
    }

    func mirrorToSyncCache() {
        let providersSnapshot = providers
        let currenciesSnapshot = fiatCurrencies
        let coinsSnapshot = coins

        syncCache { cache in
            cache.providers = providersSnapshot
            cache.fiatCurrencies = currenciesSnapshot
            cache.coins = coinsSnapshot
        }
    }
}

// MARK: - Helpers

private extension CommonTransactionHistoryAuxDataRepository {
    struct SyncCache {
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
