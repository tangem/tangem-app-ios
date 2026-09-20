//
//  MultipleAddressTransactionHistoryServiceTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Testing
import BlockchainSdk
@testable import Tangem

@Suite("MultipleAddressTransactionHistoryService — reset while loading", .timeLimit(.minutes(1)))
struct MultipleAddressTransactionHistoryServiceTests {
    private let tokenItem = TokenItem.blockchain(.init(.bitcoin(testnet: false), derivationPath: nil))

    @Test("clearHistory during an in-flight load resets the state and lets the next update run")
    func clearHistoryDuringLoadResetsState() async throws {
        let legacy = HangingProvider()
        let segwit = HangingProvider()
        let service = makeService(providers: ["legacy": legacy, "segwit": segwit])

        let firstUpdate = Task { try? await service.update().async() }
        await legacy.waitForRequest()
        #expect(service.state.isLoading)

        await service.clearHistory()

        // The cancelled pipeline never completes, so the service has to leave `.loading` on its own...
        #expect(!service.state.isLoading)
        // ...and the consumer that started the cancelled load must not be left hanging.
        await firstUpdate.value

        let secondUpdate = Task { try? await service.update().async() }
        await legacy.waitForRequest()
        #expect(service.state.isLoading, "the update after a reset must actually start loading")

        legacy.finish()
        segwit.finish()
        await secondUpdate.value

        if case .loaded = service.state {} else {
            Issue.record("expected .loaded, got \(service.state)")
        }
    }

    @Test("a second update issued while the first is loading completes instead of hanging")
    func concurrentUpdateCompletes() async throws {
        let provider = HangingProvider()
        let service = makeService(providers: ["legacy": provider])

        let firstUpdate = Task { try? await service.update().async() }
        await provider.waitForRequest()

        // Before the fix `fetch` returned early without resolving its `Future`, so this never came back.
        try? await service.update().async()

        provider.finish()
        await firstUpdate.value
    }

    private func makeService(providers: [String: HangingProvider]) -> MultipleAddressTransactionHistoryService {
        MultipleAddressTransactionHistoryService(
            tokenItem: tokenItem,
            addresses: Array(providers.keys),
            transactionHistoryProviders: providers.mapValues { $0 as BlockchainSdk.TransactionHistoryProvider }
        )
    }
}

// MARK: - Test double

/// A provider whose request stays open until `finish()` is called, so tests can act while the service is `.loading`.
private final class HangingProvider: BlockchainSdk.TransactionHistoryProvider {
    private let subject = PassthroughSubject<TransactionHistory.Response, Error>()
    private let requestReceived = AsyncStream<Void>.makeStream()

    var canFetchHistory: Bool { true }
    var description: String { "HangingProvider" }

    func loadTransactionHistory(request: TransactionHistory.Request) -> AnyPublisher<TransactionHistory.Response, Error> {
        subject
            .handleEvents(receiveSubscription: { [requestReceived] _ in requestReceived.continuation.yield() })
            .eraseToAnyPublisher()
    }

    func reset() {}

    func finish() {
        subject.send(TransactionHistory.Response(records: []))
        subject.send(completion: .finished)
    }

    func waitForRequest() async {
        for await _ in requestReceived.stream {
            return
        }
    }
}
