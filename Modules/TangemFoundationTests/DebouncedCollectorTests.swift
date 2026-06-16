//
//  DebouncedCollectorTests.swift
//  TangemFoundationTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

@preconcurrency import Combine
import Foundation
import Testing
@testable import TangemFoundation

@Suite("Publishers.DebouncedCollector tests")
struct DebouncedCollectorTests {
    // MARK: - Functional behavior

    @Test("Collects values emitted within a single debounce window into one array")
    @MainActor
    func collectsValuesWithinWindow() async throws {
        let subject = PassthroughSubject<Int, Never>()
        var received: [[Int]] = []
        let cancellable = subject
            .collect(debouncedTime: .milliseconds(50), scheduler: DispatchQueue.main)
            .sink { received.append($0) }

        subject.send(1)
        subject.send(2)
        subject.send(3)

        try await Task.sleep(for: .milliseconds(150))
        _ = cancellable

        #expect(received == [[1, 2, 3]])
    }

    @Test("Resets accumulator between two debounce windows")
    @MainActor
    func resetsAccumulatorBetweenWindows() async throws {
        let subject = PassthroughSubject<Int, Never>()
        var received: [[Int]] = []
        let cancellable = subject
            .collect(debouncedTime: .milliseconds(50), scheduler: DispatchQueue.main)
            .sink { received.append($0) }

        subject.send(1)
        subject.send(2)
        try await Task.sleep(for: .milliseconds(150))

        subject.send(3)
        subject.send(4)
        try await Task.sleep(for: .milliseconds(150))
        _ = cancellable

        #expect(received == [[1, 2], [3, 4]])
    }

    @Test("Single value within window emits array of one")
    @MainActor
    func singleValueEmitsArrayOfOne() async throws {
        let subject = PassthroughSubject<Int, Never>()
        var received: [[Int]] = []
        let cancellable = subject
            .collect(debouncedTime: .milliseconds(50), scheduler: DispatchQueue.main)
            .sink { received.append($0) }

        subject.send(42)
        try await Task.sleep(for: .milliseconds(150))
        _ = cancellable

        #expect(received == [[42]])
    }

    @Test("No upstream emissions produce no output")
    @MainActor
    func noEmissionsProduceNoOutput() async throws {
        let subject = PassthroughSubject<Int, Never>()
        var received: [[Int]] = []
        let cancellable = subject
            .collect(debouncedTime: .milliseconds(50), scheduler: DispatchQueue.main)
            .sink { received.append($0) }

        try await Task.sleep(for: .milliseconds(150))
        _ = cancellable

        #expect(received.isEmpty)
    }

    @Test("Late emissions extend the debounce window")
    @MainActor
    func lateEmissionsExtendTheWindow() async throws {
        let subject = PassthroughSubject<Int, Never>()
        var received: [[Int]] = []
        let cancellable = subject
            .collect(debouncedTime: .milliseconds(80), scheduler: DispatchQueue.main)
            .sink { received.append($0) }

        subject.send(1)
        try await Task.sleep(for: .milliseconds(40))
        subject.send(2)
        try await Task.sleep(for: .milliseconds(40))
        subject.send(3)
        try await Task.sleep(for: .milliseconds(150))
        _ = cancellable

        #expect(received == [[1, 2, 3]])
    }

    // MARK: - Concurrent access

    @Test("Concurrent subscriptions and emissions don't crash", .timeLimit(.minutes(1)))
    func concurrentSubscriptionsAndEmissionsDontCrash() async {
        for _ in 0 ..< 100 {
            nonisolated(unsafe) let subject = PassthroughSubject<Int, Never>()

            await withTaskGroup(of: Void.self) { group in
                for _ in 0 ..< 5 {
                    group.addTask {
                        nonisolated(unsafe) let cancellable = subject
                            .collect(debouncedTime: .milliseconds(5), scheduler: DispatchQueue.global())
                            .sink { _ in }
                        try? await Task.sleep(for: .milliseconds(20))
                        cancellable.cancel()
                    }
                }
                group.addTask {
                    for i in 0 ..< 30 {
                        subject.send(i)
                    }
                }
            }
        }
    }

    @Test("Concurrent emission during cancellation doesn't crash", .timeLimit(.minutes(1)))
    func concurrentEmissionDuringCancellationDoesntCrash() async {
        for _ in 0 ..< 200 {
            nonisolated(unsafe) let subject = PassthroughSubject<Int, Never>()
            nonisolated(unsafe) let cancellable = subject
                .collect(debouncedTime: .milliseconds(5), scheduler: DispatchQueue.global())
                .sink { _ in }

            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    for i in 0 ..< 20 {
                        subject.send(i)
                    }
                }
                group.addTask {
                    cancellable.cancel()
                }
            }
        }
    }
}
