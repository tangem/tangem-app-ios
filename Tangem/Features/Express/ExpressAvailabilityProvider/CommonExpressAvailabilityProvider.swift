//
//  CommonSwapAvailabilityManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdk
import TangemExpress
import TangemFoundation

class CommonExpressAvailabilityProvider {
    fileprivate typealias Availability = [ExpressCurrency: AvailabilityState]
    fileprivate typealias CurrenciesSet = Set<ExpressWalletCurrency>

    private let storage = CachesDirectoryStorage(file: .cachedExpressAvailability)
    private let _state: CurrentValueSubject<ExpressAvailabilityUpdateState, Never> = .init(.updating)
    private lazy var _cache: CurrentValueSubject<Availability, Never> = .init(loadFromDiskStorage())

    private var loadingQueue = PassthroughSubject<QueueItem, Never>()
    private let lock = OSAllocatedUnfairLock()
    private var bag: Set<AnyCancellable> = []
    private var apiProvider: ExpressAPIProvider?

    init() {
        bind()
    }
}

// MARK: - ExpressAvailabilityProvider

extension CommonExpressAvailabilityProvider: ExpressAvailabilityProvider {
    var hasCache: Bool {
        _cache.value.isNotEmpty
    }

    var expressAvailabilityUpdateStateValue: ExpressAvailabilityUpdateState {
        _state.value
    }

    var expressAvailabilityUpdateState: AnyPublisher<ExpressAvailabilityUpdateState, Never> {
        _state.eraseToAnyPublisher()
    }

    var availabilityDidChangePublisher: AnyPublisher<Void, Never> {
        _cache.mapToVoid().eraseToAnyPublisher()
    }

    func swapState(for tokenItem: TokenItem) -> TokenItemExpressState {
        _cache.value[tokenItem.expressCurrency.asCurrency]?.swap ?? .notLoaded
    }

    func canSwap(tokenItem: TokenItem) -> Bool {
        swapState(for: tokenItem) == .available
    }

    func onrampState(for tokenItem: TokenItem) -> TokenItemExpressState {
        _cache.value[tokenItem.expressCurrency.asCurrency]?.onramp ?? .notLoaded
    }

    func canOnramp(tokenItem: TokenItem) -> Bool {
        onrampState(for: tokenItem) == .available
    }

    func updateExpressAvailability(for items: [TokenItem], forceReload: Bool, userWalletId: String) {
        _state.send(.updating)
        makeApiProviderIfNeeded(userWalletId: userWalletId)
        let currencies = prepareCurrenciesSet(items: items, forceReload: forceReload)
        let item = QueueItem(currencies: currencies)
        loadingQueue.send(item)
    }
}

extension CommonExpressAvailabilityProvider {
    enum Error: Swift.Error {
        case providerNotCreated
    }
}

// MARK: - Private

private extension CommonExpressAvailabilityProvider {
    func bind() {
        loadingQueue
            .collect(debouncedTime: 0.3, scheduler: DispatchQueue.global())
            .withWeakCaptureOf(self)
            .sink(receiveValue: { provider, queueItems in
                let allCurrencies: CurrenciesSet = queueItems.reduce(into: []) { result, queueItem in
                    let joined = result.union(queueItem.currencies)
                    result = joined
                }

                provider.loadAndSave(currencies: allCurrencies)
            })
            .store(in: &bag)

        // Cached on disk
        _cache
            .dropFirst()
            .withWeakCaptureOf(self)
            .sink { $0.saveToDiskStorage(availability: $1) }
            .store(in: &bag)
    }

    func loadAndSave(currencies: CurrenciesSet) {
        runTask(in: self) { provider in
            do {
                let availabilityStates = try await provider.loadAvailabilityStates(currencies: currencies)
                provider.save(states: availabilityStates)
                provider._state.send(.updated)
            } catch {
                ExpressLogger.error("Failed to load availability states", error: error)
                Analytics.error(error: error)

                provider._state.send(.failed(error: error))
            }
        }
    }

    func loadAvailabilityStates(currencies: CurrenciesSet) async throws -> Availability {
        let provider = try getApiProvider()
        let assets = try await provider.assets(currencies: currencies)

        return assets.reduce(into: [:]) { result, asset in
            result[asset.currency] = .init(
                swap: asset.isExchangeable ? .available : .unavailable,
                onramp: asset.isOnrampable ? .available : .unavailable
            )
        }
    }

    func save(states: Availability) {
        lock {
            var items = _cache.value

            states.forEach { key, value in
                items.updateValue(value, forKey: key)
            }

            _cache.send(items)
        }
    }

    func prepareCurrenciesSet(items: [TokenItem], forceReload: Bool) -> CurrenciesSet {
        if items.isEmpty {
            return []
        }

        let itemsToRequest = items.filter {
            // If `forceReload` flag is true we need to force reload state for all items
            return _cache.value[$0.expressCurrency.asCurrency] == nil || forceReload
        }

        // This mean that all requesting items in blockchains that currently not available for swap
        // We can exit without request
        if itemsToRequest.isEmpty {
            return []
        }

        return itemsToRequest.map { $0.expressCurrency }.toSet()
    }

    func getApiProvider() throws -> ExpressAPIProvider {
        guard let apiProvider else {
            throw Error.providerNotCreated
        }

        return apiProvider
    }

    func makeApiProviderIfNeeded(userWalletId: String) {
        guard self.apiProvider == nil else {
            return
        }

        let apiProvider = ExpressAPIProviderFactory().makeExpressAPIProvider(
            userId: userWalletId,
            refcode: nil
        )

        self.apiProvider = apiProvider
    }
}

// MARK: - Private

private extension CommonExpressAvailabilityProvider {
    func saveToDiskStorage(availability: Availability) {
        let models = availability
            .map { StorageModel(currency: $0, availability: $1) }
            .unique(by: \.currency)

        do {
            try storage.storeAndWait(value: models)
        } catch {
            ExpressLogger.error("Failed", error: error)
        }
    }

    func loadFromDiskStorage() -> Availability {
        do {
            let models: [StorageModel] = try storage.value()
            ExpressLogger.info("Success with values count: \(models.count)")
            return models.reduce(into: [:]) {
                $0[$1.currency] = $1.availability
            }
        } catch {
            ExpressLogger.error("Failed", error: error)
            return [:]
        }
    }
}

private extension CommonExpressAvailabilityProvider {
    struct AvailabilityState: Hashable, Codable {
        let swap: TokenItemExpressState
        let onramp: TokenItemExpressState
    }
}

private extension CommonExpressAvailabilityProvider {
    struct QueueItem {
        let currencies: CurrenciesSet
    }
}

private extension CommonExpressAvailabilityProvider {
    struct StorageModel: Codable {
        let currency: ExpressCurrency
        let availability: AvailabilityState
    }
}
