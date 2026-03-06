//
//  SafeNetworkMonitorTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import Testing
import WalletConnectRelay
@testable import Tangem

final class SafeNetworkMonitorTests {
    // MARK: - isConnected

    @Test
    func isConnectedReturnsTrueByDefault() {
        let sut = TestableNetworkMonitor()

        #expect(sut.isConnected)
    }

    // MARK: - Publisher behavior

    @Test
    func publisherEmitsCurrentValueOnSubscription() async {
        let sut = TestableNetworkMonitor()
        var receivedValues = [NetworkConnectionStatus]()

        let expectation = Expectation()
        let cancellable = sut.networkConnectionStatusPublisher
            .sink { value in
                receivedValues.append(value)
                expectation.fulfill()
            }

        await expectation.fulfillment(within: .seconds(2))

        #expect(receivedValues == [.connected])
        _ = cancellable
    }

    @Test
    func isConnectedReflectsPublisherState() {
        let sut = TestableNetworkMonitor()

        // Initial state should be connected (default for CurrentValueSubject)
        #expect(sut.isConnected == true)
    }

    @Test
    func multipleSubscribersEachReceiveCurrentValue() async {
        let sut = TestableNetworkMonitor()

        var values1 = [NetworkConnectionStatus]()
        var values2 = [NetworkConnectionStatus]()

        let expectation1 = Expectation()
        let expectation2 = Expectation()

        let cancellable1 = sut.networkConnectionStatusPublisher
            .sink { value in
                values1.append(value)
                expectation1.fulfill()
            }

        let cancellable2 = sut.networkConnectionStatusPublisher
            .sink { value in
                values2.append(value)
                expectation2.fulfill()
            }

        await expectation1.fulfillment(within: .seconds(2))
        await expectation2.fulfillment(within: .seconds(2))

        #expect(values1 == [.connected])
        #expect(values2 == [.connected])
        _ = (cancellable1, cancellable2)
    }

    // MARK: - removeDuplicates verification via subject simulation

    @Test
    func removeDuplicatesFiltersDuplicateConnectedEvents() async throws {
        let sut = TestableNetworkMonitor()

        var receivedValues = [NetworkConnectionStatus]()
        let expectation = Expectation()

        let cancellable = sut.networkConnectionStatusPublisher
            .collect(.byTime(DispatchQueue.main, .milliseconds(200)))
            .sink { values in
                receivedValues.append(contentsOf: values)
                expectation.fulfill()
            }

        // Send duplicate .connected events
        sut.simulateStatus(.connected)
        sut.simulateStatus(.connected)
        sut.simulateStatus(.connected)

        await expectation.fulfillment(within: .seconds(2))

        // removeDuplicates should filter consecutive duplicates
        // Initial .connected from CurrentValueSubject + 3 more .connected = all filtered to 1
        #expect(receivedValues == [.connected])
        _ = cancellable
    }

    @Test
    func removeDuplicatesAllowsGenuineStatusChanges() async throws {
        let sut = TestableNetworkMonitor()

        var receivedValues = [NetworkConnectionStatus]()
        let expectation = Expectation()

        let cancellable = sut.networkConnectionStatusPublisher
            .collect(.byTime(DispatchQueue.main, .milliseconds(300)))
            .sink { values in
                receivedValues.append(contentsOf: values)
                expectation.fulfill()
            }

        // Send genuine status changes
        sut.simulateStatus(.notConnected)
        sut.simulateStatus(.connected)

        await expectation.fulfillment(within: .seconds(2))

        // Should receive: initial .connected, then .notConnected, then .connected
        #expect(receivedValues == [.connected, .notConnected, .connected])
        _ = cancellable
    }

    @Test
    func removeDuplicatesFiltersRepeatedNotConnected() async throws {
        let sut = TestableNetworkMonitor()

        var receivedValues = [NetworkConnectionStatus]()
        let expectation = Expectation()

        let cancellable = sut.networkConnectionStatusPublisher
            .collect(.byTime(DispatchQueue.main, .milliseconds(300)))
            .sink { values in
                receivedValues.append(contentsOf: values)
                expectation.fulfill()
            }

        sut.simulateStatus(.notConnected)
        sut.simulateStatus(.notConnected)
        sut.simulateStatus(.notConnected)

        await expectation.fulfillment(within: .seconds(2))

        // Should receive: initial .connected, then one .notConnected (duplicates filtered)
        #expect(receivedValues == [.connected, .notConnected])
        _ = cancellable
    }

    @Test
    func removeDuplicatesHandlesRapidAlternation() async throws {
        let sut = TestableNetworkMonitor()

        var receivedValues = [NetworkConnectionStatus]()
        let expectation = Expectation()

        let cancellable = sut.networkConnectionStatusPublisher
            .collect(.byTime(DispatchQueue.main, .milliseconds(300)))
            .sink { values in
                receivedValues.append(contentsOf: values)
                expectation.fulfill()
            }

        // Rapid alternation
        sut.simulateStatus(.notConnected)
        sut.simulateStatus(.connected)
        sut.simulateStatus(.notConnected)
        sut.simulateStatus(.connected)

        await expectation.fulfillment(within: .seconds(2))

        // All changes are genuine (not consecutive duplicates), so all pass through
        #expect(receivedValues == [.connected, .notConnected, .connected, .notConnected, .connected])
        _ = cancellable
    }

    @Test
    func isConnectedReturnsFalseAfterDisconnection() {
        let sut = TestableNetworkMonitor()

        sut.simulateStatus(.notConnected)

        #expect(sut.isConnected == false)
    }

    @Test
    func isConnectedReturnsTrueAfterReconnection() {
        let sut = TestableNetworkMonitor()

        sut.simulateStatus(.notConnected)
        #expect(sut.isConnected == false)

        sut.simulateStatus(.connected)
        #expect(sut.isConnected == true)
    }

    @Test
    func subscriptionCancellationStopsDelivery() async throws {
        let sut = TestableNetworkMonitor()

        var receivedValues = [NetworkConnectionStatus]()

        let cancellable = sut.networkConnectionStatusPublisher
            .sink { value in
                receivedValues.append(value)
            }

        // Should receive initial value
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        #expect(receivedValues == [.connected])

        // Cancel subscription
        cancellable.cancel()

        // Simulate status change after cancellation
        sut.simulateStatus(.notConnected)
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms

        // Should NOT receive the new value
        #expect(receivedValues == [.connected])
    }
}

// MARK: - TestableNetworkMonitor

/// A testable version of SafeNetworkMonitor that bypasses NWPathMonitor
/// and allows direct control of the status subject.
private final class TestableNetworkMonitor: NetworkMonitoring {
    private let subject = CurrentValueSubject<NetworkConnectionStatus, Never>(.connected)

    var isConnected: Bool {
        subject.value == .connected
    }

    var networkConnectionStatusPublisher: AnyPublisher<NetworkConnectionStatus, Never> {
        subject
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    func simulateStatus(_ status: NetworkConnectionStatus) {
        subject.send(status)
    }
}

// MARK: - Expectation helper

private final class Expectation: @unchecked Sendable {
    private let state = State()

    func fulfill() {
        Task {
            await state.fulfill()
        }
    }

    func fulfillment(within timeout: Duration) async {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: timeout)

        while clock.now < deadline {
            if await state.isFulfilled() {
                return
            }

            try? await Task.sleep(for: .milliseconds(10))
        }

        #expect(Bool(false), "Expectation was not fulfilled within the given timeout.")
    }
}

private actor State {
    private var isFulfilledValue = false

    func fulfill() {
        isFulfilledValue = true
    }

    func isFulfilled() -> Bool {
        isFulfilledValue
    }
}
