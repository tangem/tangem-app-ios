//
//  TokenExpressAvailabilityReloaderTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Testing
import BlockchainSdk
import TangemFoundation
@testable import Tangem

@Suite("TokenExpressAvailabilityReloader")
struct TokenExpressAvailabilityReloaderTests {
    private let tokenItem = TokenItem.blockchain(BlockchainNetwork(.polygon(testnet: false), derivationPath: nil))

    @Test(arguments: [false, true])
    func reloadsNotLoadedAvailabilityAndWaitsForItsOutcome(expressFails: Bool) async throws {
        let provider = ExpressAvailabilityProviderStub(swap: .notLoaded, onramp: .notLoaded)
        let reloader = makeReloader(provider: provider, shouldLoadExpressAvailability: true)

        let isFinished = OSAllocatedUnfairLock(initialState: false)
        let reload = Task {
            await reloader.reloadIfNeeded()
            isFinished.withLock { $0 = true }
        }

        for _ in 0 ..< 40 where provider.requests.isEmpty {
            try await Task.sleep(for: .milliseconds(25))
        }
        try await Task.sleep(for: .milliseconds(100))

        #expect(provider.requests == [ExpressAvailabilityProviderStub.Request(tokenItems: [tokenItem], forceReload: true)])
        #expect(!isFinished.withLock { $0 }, "The refresh went on before the availability load finished")

        provider.finishUpdate(with: expressFails ? .failed(error: URLError(.notConnectedToInternet)) : .updated)
        await reload.value

        #expect(isFinished.withLock { $0 })
    }

    @Test(arguments: [
        (TokenItemExpressState.available, TokenItemExpressState.available, true),
        (TokenItemExpressState.notLoaded, TokenItemExpressState.unavailable, true),
        (TokenItemExpressState.notLoaded, TokenItemExpressState.notLoaded, false),
    ])
    func leavesAvailabilityAloneWhenAlreadyLoadedOrNotUsed(
        swap: TokenItemExpressState,
        onramp: TokenItemExpressState,
        shouldLoadExpressAvailability: Bool
    ) async throws {
        let provider = ExpressAvailabilityProviderStub(swap: swap, onramp: onramp)
        let reloader = makeReloader(provider: provider, shouldLoadExpressAvailability: shouldLoadExpressAvailability)

        let reload = Task { await reloader.reloadIfNeeded() }
        try await Task.sleep(for: .milliseconds(100))
        provider.finishUpdate(with: .updated)
        await reload.value

        #expect(provider.requests.isEmpty)
    }

    @Test(.timeLimit(.minutes(1)))
    func doesNotMissAnOutcomeThatArrivesBeforeItIsAwaited() async {
        let provider = ExpressAvailabilityProviderStub(swap: .notLoaded, onramp: .notLoaded)
        provider.finishUpdatesInstantly()

        await makeReloader(provider: provider, shouldLoadExpressAvailability: true).reloadIfNeeded()

        #expect(provider.requests == [ExpressAvailabilityProviderStub.Request(tokenItems: [tokenItem], forceReload: true)])
    }

    private func makeReloader(
        provider: ExpressAvailabilityProviderStub,
        shouldLoadExpressAvailability: Bool
    ) -> TokenExpressAvailabilityReloader {
        TokenExpressAvailabilityReloader(
            expressAvailabilityProvider: provider,
            tokenItem: tokenItem,
            userWalletId: UserWalletId(value: Data()),
            shouldLoadExpressAvailability: shouldLoadExpressAvailability
        )
    }
}

// MARK: - Stubs

private final class ExpressAvailabilityProviderStub: ExpressAvailabilityProvider {
    struct Request: Equatable {
        let tokenItems: [TokenItem]
        let forceReload: Bool
    }

    private static let updateStartLatency: TimeInterval = 0.05

    private let swap: TokenItemExpressState
    private let onramp: TokenItemExpressState
    private let stateSubject = CurrentValueSubject<ExpressAvailabilityUpdateState, Never>(.updated)
    private let recordedRequests = OSAllocatedUnfairLock<[Request]>(initialState: [])
    private let finishesInstantly = OSAllocatedUnfairLock(initialState: false)

    init(swap: TokenItemExpressState, onramp: TokenItemExpressState) {
        self.swap = swap
        self.onramp = onramp
    }

    var requests: [Request] {
        recordedRequests.withLock { $0 }
    }

    func finishUpdate(with state: ExpressAvailabilityUpdateState) {
        stateSubject.send(state)
    }

    func finishUpdatesInstantly() {
        finishesInstantly.withLock { $0 = true }
    }

    var hasCache: Bool { true }
    var availabilityDidChangePublisher: AnyPublisher<Void, Never> { Empty().eraseToAnyPublisher() }
    var expressAvailabilityUpdateStateValue: ExpressAvailabilityUpdateState { stateSubject.value }
    var expressAvailabilityUpdateState: AnyPublisher<ExpressAvailabilityUpdateState, Never> { stateSubject.eraseToAnyPublisher() }

    func swapState(for tokenItem: TokenItem) -> TokenItemExpressState { swap }
    func onrampState(for tokenItem: TokenItem) -> TokenItemExpressState { onramp }
    func canSwap(tokenItem: TokenItem) -> Bool { swap == .available }
    func canOnramp(tokenItem: TokenItem) -> Bool { onramp == .available }

    func updateExpressAvailability(for items: [TokenItem], forceReload: Bool, userWalletId: String) {
        recordedRequests.withLock { $0.append(Request(tokenItems: items, forceReload: forceReload)) }
        Thread.sleep(forTimeInterval: Self.updateStartLatency)
        stateSubject.send(.updating)

        if finishesInstantly.withLock({ $0 }) {
            stateSubject.send(.updated)
        }
    }
}
