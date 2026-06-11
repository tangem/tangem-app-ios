//
//  WalletTransactionHistoryService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import Combine
import TangemFoundation
import os

final class WalletTransactionHistoryService {
    private let tokenItem: TokenItem
    private let walletProvider: WalletProvider
    private let transactionHistoryProviderFactory: BlockchainSdk.TransactionHistoryProviderFactory

    private let _state = CurrentValueSubject<TransactionHistoryServiceState, Never>(.initial)
    private let pageSize: Int = 100

    private let syncState = OSAllocatedUnfairLock(initialState: SyncState())
    private var keyTypeSubscription: AnyCancellable?

    init(
        tokenItem: TokenItem,
        walletProvider: WalletProvider,
        transactionHistoryProviderFactory: BlockchainSdk.TransactionHistoryProviderFactory
    ) {
        self.tokenItem = tokenItem
        self.walletProvider = walletProvider
        self.transactionHistoryProviderFactory = transactionHistoryProviderFactory
        bind()
    }
}

// MARK: - TransactionHistoryService

extension WalletTransactionHistoryService: TransactionHistoryService {
    var state: TransactionHistoryServiceState {
        _state.value
    }

    var statePublisher: AnyPublisher<TransactionHistoryServiceState, Never> {
        _state.eraseToAnyPublisher()
    }

    var items: [TransactionRecord] {
        syncState.withLock(\.storage)
    }

    var canFetchHistory: Bool {
        syncState.withLock { state in
            state.providers.contains { $0.provider.canFetchHistory }
        }
    }

    func clearHistory() {
        let (providers, task, pending) = syncState.withLock { state -> ([Entry], Task<Void, Never>?, [@Sendable () -> Void]) in
            let task = state.updateTask
            let pending = state.pendingCompletions
            state.updateTask = nil
            state.pendingCompletions.removeAll()
            state.storage.removeAll()
            return (state.providers, task, pending)
        }
        task?.cancel()
        providers.forEach { $0.provider.reset() }
        _state.send(.initial)
        pending.forEach { $0() }
        AppLogger.info(self, "was reset")
    }

    func update() -> AnyPublisher<Void, Never> {
        Deferred { [weak self] in
            Future { promise in
                guard let self else {
                    promise(.success(()))
                    return
                }

                self.startUpdate { promise(.success(())) }
            }
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension WalletTransactionHistoryService {
    func bind() {
        keyTypeSubscription = walletProvider.walletPublisher
            .compactMap { wallet -> WalletUpdatingKeyType? in
                try? wallet.updatingKeyType()
            }
            .withWeakCaptureOf(self)
            .map { $0.makeRequestInput(from: $1) }
            .removeDuplicates()
            .receiveOnMain()
            .sink { [weak self] input in
                self?.rebuildProviders(for: input)
            }
    }

    func rebuildProviders(for input: RequestInput) {
        let newProviders: [Entry] = input.keys.compactMap { key in
            makeProvider().map { Entry(key: key, walletAddressType: input.walletAddressType, provider: $0) }
        }

        let (oldProviders, oldTask, pending) = syncState.withLock { state -> ([Entry], Task<Void, Never>?, [@Sendable () -> Void]) in
            let oldProviders = state.providers
            let oldTask = state.updateTask
            let pending = state.pendingCompletions
            state.providers = newProviders
            state.updateTask = nil
            state.pendingCompletions.removeAll()
            state.storage.removeAll()
            return (oldProviders, oldTask, pending)
        }
        oldTask?.cancel()
        oldProviders.forEach { $0.provider.reset() }
        _state.send(.initial)
        pending.forEach { $0() }
        AppLogger.info(self, "providers rebuilt for \(newProviders.count) key(s)")

        // A key change resets to `.initial` (a spinner in the UI). Kick off the load here so
        // history starts fetching immediately, instead of waiting for an external `update()`
        // that races with this rebuild and may have already run against the old key.
        if !newProviders.isEmpty {
            startUpdate {}
        }
    }

    func makeProvider() -> BlockchainSdk.TransactionHistoryProvider? {
        transactionHistoryProviderFactory.makeProvider(
            for: tokenItem.blockchain,
            isToken: tokenItem.isToken
        )
    }

    func startUpdate(completion: @escaping @Sendable () -> Void) {
        let shouldStart: Bool = syncState.withLock { state in
            let wasIdle = state.updateTask == nil
            state.pendingCompletions.append(completion)
            if wasIdle {
                state.updateTask = Task { [weak self] in
                    await self?.fetch()
                    self?.fireCompletions()
                }
            }
            return wasIdle
        }

        if !shouldStart {
            AppLogger.info(self, "already is loading, queued")
        }
    }

    func fireCompletions() {
        let completions = syncState.withLock { state -> [@Sendable () -> Void] in
            // If the task was cancelled, clearHistory/rebuildProviders has already drained pendingCompletions.
            guard !Task.isCancelled else {
                return []
            }
            let pending = state.pendingCompletions
            state.pendingCompletions.removeAll()
            state.updateTask = nil
            return pending
        }
        completions.forEach { $0() }
    }

    func fetch() async {
        do {
            try Task.checkCancellation()

            let activeEntries: [Entry] = syncState.withLock { state in
                state.providers.filter { $0.provider.canFetchHistory }
            }

            guard !activeEntries.isEmpty else {
                AppLogger.info(self, "reached the end of list")
                return
            }

            AppLogger.info(self, "start loading")
            _state.send(.loading)

            let responses = try await TaskGroup.tryExecuteKeepingOrder(items: activeEntries) { [tokenItem, pageSize] entry in
                let request = TransactionHistory.Request(
                    key: entry.key,
                    walletAddressType: entry.walletAddressType,
                    amountType: tokenItem.amountType,
                    limit: pageSize
                )
                return try await entry.provider.loadTransactionHistory(request: request).async()
            }

            try Task.checkCancellation()

            let wrote: Bool = syncState.withLock { state in
                guard !Task.isCancelled else { return false }
                for response in responses {
                    state.storage.appendMerging(response.records)
                }
                return true
            }

            if wrote {
                AppLogger.info(self, "loaded")
                _state.send(.loaded)
            }
        } catch is CancellationError {
            if _state.value.isLoading {
                _state.send(.initial)
            }
        } catch {
            guard !Task.isCancelled else { return }
            _state.send(.failedToLoad(error))
            AppLogger.error(self, error: error)
        }
    }

    func makeRequestInput(from keyType: WalletUpdatingKeyType) -> RequestInput {
        switch keyType {
        case .address(let address):
            return RequestInput(
                walletAddressType: .address(address.value),
                keys: [.address(address.value)]
            )
        case .addresses(let addresses):
            let values = addresses.map(\.value)
            return RequestInput(
                walletAddressType: .addresses(values),
                keys: values.map { .address($0) }
            )
        case .xpub(let xpub):
            let walletAddresses = walletProvider.wallet.addresses.map(\.value)
            return RequestInput(
                walletAddressType: .addresses(walletAddresses),
                keys: [.xpub(xpub.wrapped())]
            )
        case .xpubs(let xpubs):
            let walletAddresses = walletProvider.wallet.addresses.map(\.value)
            return RequestInput(
                walletAddressType: .addresses(walletAddresses),
                keys: xpubs.map { .xpub($0.wrapped()) }
            )
        }
    }
}

// MARK: - Nested types

extension WalletTransactionHistoryService {
    struct RequestInput: Hashable {
        let walletAddressType: TransactionHistory.Request.WalletAddressType
        let keys: [TransactionHistory.Request.Key]
    }

    struct Entry {
        let key: TransactionHistory.Request.Key
        let walletAddressType: TransactionHistory.Request.WalletAddressType
        let provider: BlockchainSdk.TransactionHistoryProvider
    }

    private struct SyncState {
        var providers: [Entry] = []
        var storage: [TransactionRecord] = []
        var updateTask: Task<Void, Never>?
        var pendingCompletions: [@Sendable () -> Void] = []
    }
}

// MARK: - CustomStringConvertible

extension WalletTransactionHistoryService: CustomStringConvertible {
    var description: String {
        objectDescription(
            self,
            userInfo: [
                "name": tokenItem.name,
                "type": tokenItem.isToken ? "Token" : "Coin",
            ]
        )
    }
}
