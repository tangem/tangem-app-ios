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

    /// Actor-protected cache for isolated asynchronous access.
    private var cache = Cache()

    /// Lock-protected cache for nonisolated synchronous access.
    private nonisolated let syncCache = OSAllocatedUnfairLock(initialState: Cache())

    private var subscribers = AsyncStream<Void>.MulticastSubscribers<UUID>()

    private var inFlightProvidersLoadTask: Task<Void, Never>?
    private var inFlightFiatCurrenciesLoadTask: Task<Void, Never>?

    private var pendingCryptoCurrencies: [String: ExpressCurrency] = [:]
    private var inFlightCryptoCurrencyKeys: Set<String> = []
    private var cryptoCurrencyWaiters: [String: [CheckedContinuation<Void, Never>]] = [:]
    private var cryptoCurrenciesDebounceTask: Task<Void, Never>?

    private let cachingExpressAPIProviderFactory: CachingExpressAPIProviderFactory
    private let storage: UserDefaultsTransactionHistoryAuxDataStorage

    init(
        cachingExpressAPIProviderFactory: CachingExpressAPIProviderFactory,
        storage: UserDefaultsTransactionHistoryAuxDataStorage
    ) {
        self.cachingExpressAPIProviderFactory = cachingExpressAPIProviderFactory
        self.storage = storage

        let cacheFromStorage = Self.makeCache(from: storage)
        cache = cacheFromStorage
        syncCache { $0 = cacheFromStorage }
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
            runTask(in: self) { repository in
                await repository.loadProvidersIfNeeded()
            }
        }

        return cached
    }

    func provider(id: ExpressProvider.Id) async -> ExpressProvider? {
        if let cached = cache.providers[id] {
            return cached
        }

        await loadProvidersIfNeeded()

        return cache.providers[id]
    }

    // MARK: Fiat currencies

    nonisolated func fiatCurrency(for asset: OnrampHistoryFiatAsset) -> OnrampFiatCurrency? {
        let cached = syncCache { $0.fiatCurrencies[asset.currencyCode] }

        if cached == nil {
            runTask(in: self) { repository in
                await repository.loadFiatCurrenciesIfNeeded()
            }
        }

        return cached
    }

    func fiatCurrency(for asset: OnrampHistoryFiatAsset) async -> OnrampFiatCurrency? {
        if let cached = cache.fiatCurrencies[asset.currencyCode] {
            return cached
        }

        await loadFiatCurrenciesIfNeeded()

        return cache.fiatCurrencies[asset.currencyCode]
    }

    // MARK: Crypto currencies

    nonisolated func cryptoCurrency(for currency: ExpressCurrency) -> TokenItem? {
        let key = Self.makeCryptoCurrencyCacheKey(for: currency)
        let cached = syncCache { $0.cryptoCurrencies[key] }

        if cached == nil {
            runTask(in: self) { repository in
                await repository.loadCryptoCurrenciesIfNeeded(currency, key: key, isFromAsyncContext: false)
            }
        }

        return cached
    }

    func cryptoCurrency(for currency: ExpressCurrency) async -> TokenItem? {
        let key = Self.makeCryptoCurrencyCacheKey(for: currency)

        if let cached = cache.cryptoCurrencies[key] {
            return cached
        }

        await loadCryptoCurrenciesIfNeeded(currency, key: key, isFromAsyncContext: true)

        return cache.cryptoCurrencies[key]
    }
}

// MARK: - Providers / currencies loading

private extension CommonTransactionHistoryAuxDataRepository {
    func makeExpressAPIProvider() -> ExpressAPIProvider? {
        // We don't care about using a particular user wallet model here, any will do,
        // since we just need to create a provider to fetch non-user-specific data (providers, currencies, etc)
        guard let model = userWalletRepository.selectedModel ?? userWalletRepository.models.first else {
            return nil
        }

        return cachingExpressAPIProviderFactory.provider(
            for: model.userWalletId.stringValue,
            refcode: model.refcodeProvider?.getRefcode()
        )
    }

    func loadProvidersIfNeeded() async {
        if let task = inFlightProvidersLoadTask {
            return await task.value
        }

        let task = Task { [weak self] in
            try? await Task.sleep(for: Constants.debounce)
            await self?.performProvidersLoad()
        }

        defer { inFlightProvidersLoadTask = nil }
        inFlightProvidersLoadTask = task
        await task.value
    }

    func performProvidersLoad() async {
        guard let expressAPIProvider = makeExpressAPIProvider() else {
            TransactionHistoryLogger.error(self, error: "Failed to create ExpressAPIProvider for providers load")
            return
        }

        do {
            let swap = try await expressAPIProvider.providers(branch: .swap)
            let onramp = try await expressAPIProvider.providers(branch: .onramp)
            var hasChanges = false

            for provider in swap + onramp {
                if cache.providers[provider.id] != provider {
                    cache.providers[provider.id] = provider
                    hasChanges = true
                }
            }

            guard hasChanges else {
                return
            }

            mirrorToSyncCache()
            persistProviders()
            subscribers.yield()
        } catch {
            TransactionHistoryLogger.error(self, "Failed to load Express providers", error: error)
        }
    }

    func loadFiatCurrenciesIfNeeded() async {
        if let task = inFlightFiatCurrenciesLoadTask {
            await task.value

            return
        }

        let task = Task { [self] in
            try? await Task.sleep(for: Constants.debounce)
            await performCurrenciesLoad()
        }
        inFlightFiatCurrenciesLoadTask = task
        defer { inFlightFiatCurrenciesLoadTask = nil }
        await task.value
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
            persistCurrencies()
            subscribers.yield()
        } catch {
            TransactionHistoryLogger.error(self, "Failed to load onramp currencies", error: error)
        }
    }
}

// MARK: - Crypto currencies loading

private extension CommonTransactionHistoryAuxDataRepository {
    func loadCryptoCurrenciesIfNeeded(_ currency: ExpressCurrency, key: String, isFromAsyncContext: Bool) async {
        if cache.cryptoCurrencies[key] != nil {
            return
        }

        if !inFlightCryptoCurrencyKeys.contains(key) {
            pendingCryptoCurrencies[key] = currency
            armCryptoCurrenciesDebounce()
        }

        guard isFromAsyncContext else {
            return
        }

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            if cache.cryptoCurrencies[key] != nil {
                continuation.resume()

                return
            }

            cryptoCurrencyWaiters[key, default: []].append(continuation)
        }
    }

    func armCryptoCurrenciesDebounce() {
        cryptoCurrenciesDebounceTask?.cancel()
        cryptoCurrenciesDebounceTask = Task { [self] in
            try? await Task.sleep(for: Constants.debounce)

            guard !Task.isCancelled else {
                return
            }

            await flushPendingCryptoCurrencies()
        }
    }

    func flushPendingCryptoCurrencies() async {
        let batch = pendingCryptoCurrencies // claim atomically (no await above → no interleave)

        guard !batch.isEmpty else {
            return
        }

        pendingCryptoCurrencies.removeAll()
        inFlightCryptoCurrencyKeys.formUnion(batch.keys)

        await performCryptoCurrenciesLoad(batch)
    }

    func performCryptoCurrenciesLoad(_ batch: [String: ExpressCurrency]) async {
        defer {
            inFlightCryptoCurrencyKeys.subtract(batch.keys)
            resumeCryptoCurrencyWaiters(for: batch.keys.toSet()) // resume on success AND failure so callers never hang
        }

        do {
            let currencies = Array(batch.values)
            let networkIds = currencies.map(\.network).toSet()
            // Using `SupportedBlockchains.all` here is safe because it is just a static lookup table, while the actual list
            // of blockchains is derived from `batch` hence all of them guaranteed to be supported
            let allSupportedBlockchains = SupportedBlockchains.all
            let blockchains = networkIds.compactMap { allSupportedBlockchains[$0] }.toSet()
            let contractAddresses = currencies
                .map(\.contractAddress)
                .filter { $0 != ExpressConstants.coinContractAddress }

            let request = CoinsList.Request(
                supportedBlockchains: blockchains,
                contractAddresses: contractAddresses.nilIfEmpty
            )
            let response = try await tangemApiService.loadCoins(requestModel: request)
            let tokenItems = Self.makeTokenItems(
                from: response,
                supportedBlockchains: blockchains,
                requestedKeys: batch.keys.toSet()
            )

            var changed = false

            for (key, tokenItem) in tokenItems {
                if cache.cryptoCurrencies[key] == nil {
                    cache.cryptoCurrencies[key] = tokenItem
                    changed = true
                }
            }

            guard changed else {
                return
            }

            mirrorToSyncCache()
            persistCryptoCurrencies()
            subscribers.yield()
        } catch {
            TransactionHistoryLogger.error(self, "Failed to load crypto currencies", error: error)
        }
    }

    func resumeCryptoCurrencyWaiters(for keys: Set<String>) {
        for key in keys {
            guard let waiters = cryptoCurrencyWaiters.removeValue(forKey: key) else {
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
    func persistProviders() {
        storage.providers = Array(cache.providers.values)
    }

    func persistCurrencies() {
        storage.fiatCurrencies = Array(cache.fiatCurrencies.values)
    }

    func persistCryptoCurrencies() {
        storage.cryptoCurrencies = cache.cryptoCurrencies
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
        var cryptoCurrencies: [String: TokenItem] = [:]
    }

    static func makeCache(from storage: UserDefaultsTransactionHistoryAuxDataStorage) -> Cache {
        var cache = Cache()

        for provider in storage.providers {
            cache.providers[provider.id] = provider
        }

        for currency in storage.fiatCurrencies {
            cache.fiatCurrencies[currency.identity.code] = currency
        }

        cache.cryptoCurrencies = storage.cryptoCurrencies

        return cache
    }

    enum Constants {
        static let debounce: Duration = .milliseconds(300)
    }

    static func makeCryptoCurrencyCacheKey(networkId: String, contractAddress: String?) -> String {
        return "\(networkId)_\(contractAddress ?? ExpressConstants.coinContractAddress))"
    }

    static func makeCryptoCurrencyCacheKey(for currency: ExpressCurrency) -> String {
        // A native coin's contract address is a sentinel, normalized to `nil` to match `TokenItem`.
        let contractAddress = currency.contractAddress == ExpressConstants.coinContractAddress ? nil : currency.contractAddress

        return makeCryptoCurrencyCacheKey(networkId: currency.network, contractAddress: contractAddress)
    }

    static func makeTokenItems(
        from response: CoinsList.Response,
        supportedBlockchains: Set<Blockchain>,
        requestedKeys: Set<String>
    ) -> [String: TokenItem] {
        let coinModels = CoinsResponseMapper(supportedBlockchains: supportedBlockchains).mapToCoinModels(response)
        var result: [String: TokenItem] = [:]

        for coinModel in coinModels {
            for item in coinModel.items {
                let key = makeCryptoCurrencyCacheKey(
                    networkId: item.tokenItem.networkId,
                    contractAddress: item.tokenItem.contractAddress
                )

                if requestedKeys.contains(key) {
                    result[key] = item.tokenItem
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
