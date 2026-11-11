//
//  DebouncedCollectorTests.swift
//  TangemFoundationTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import Combine
@testable import TangemFoundation

@Suite("Publishers.DebouncedCollector tests")
struct DebouncedCollectorTests {
    // MARK: - Functional behavior

    @Test("Collects values emitted within a single debounce window into one array")
    func collectsValuesWithinWindow() {
        let scheduler = ManualSchedulerStub()
        let subject = PassthroughSubject<Int, Never>()
        var received: [[Int]] = []
        let cancellable = subject
            .collect(debouncedTime: .milliseconds(50), scheduler: scheduler)
            .sink { received.append($0) }

        subject.send(1)
        subject.send(2)
        subject.send(3)
        scheduler.advance(by: .milliseconds(50))
        _ = cancellable

        #expect(received == [[1, 2, 3]])
    }

    @Test("Resets accumulator between two debounce windows")
    func resetsAccumulatorBetweenWindows() {
        let scheduler = ManualSchedulerStub()
        let subject = PassthroughSubject<Int, Never>()
        var received: [[Int]] = []
        let cancellable = subject
            .collect(debouncedTime: .milliseconds(50), scheduler: scheduler)
            .sink { received.append($0) }

        subject.send(1)
        subject.send(2)
        scheduler.advance(by: .milliseconds(50))

        subject.send(3)
        subject.send(4)
        scheduler.advance(by: .milliseconds(50))
        _ = cancellable

        #expect(received == [[1, 2], [3, 4]])
    }

    @Test("Single value within window emits array of one")
    func singleValueEmitsArrayOfOne() {
        let scheduler = ManualSchedulerStub()
        let subject = PassthroughSubject<Int, Never>()
        var received: [[Int]] = []
        let cancellable = subject
            .collect(debouncedTime: .milliseconds(50), scheduler: scheduler)
            .sink { received.append($0) }

        subject.send(42)
        scheduler.advance(by: .milliseconds(50))
        _ = cancellable

        #expect(received == [[42]])
    }

    @Test("No upstream emissions produce no output")
    func noEmissionsProduceNoOutput() {
        let scheduler = ManualSchedulerStub()
        let subject = PassthroughSubject<Int, Never>()
        var received: [[Int]] = []
        let cancellable = subject
            .collect(debouncedTime: .milliseconds(50), scheduler: scheduler)
            .sink { received.append($0) }

        scheduler.advance(by: .milliseconds(50))
        _ = cancellable

        #expect(received.isEmpty)
    }

    @Test("Late emissions extend the debounce window")
    func lateEmissionsExtendTheWindow() {
        let scheduler = ManualSchedulerStub()
        let subject = PassthroughSubject<Int, Never>()
        var received: [[Int]] = []
        let cancellable = subject
            .collect(debouncedTime: .milliseconds(80), scheduler: scheduler)
            .sink { received.append($0) }

        subject.send(1)
        scheduler.advance(by: .milliseconds(40))
        subject.send(2)
        scheduler.advance(by: .milliseconds(40))
        subject.send(3)
        scheduler.advance(by: .milliseconds(79))

        #expect(received.isEmpty)

        scheduler.advance(by: .milliseconds(1))
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

// MARK: - Stubs

private final class ManualSchedulerStub: Scheduler {
    typealias SchedulerTimeType = DispatchQueue.SchedulerTimeType
    typealias SchedulerOptions = DispatchQueue.SchedulerOptions

    private(set) var now = SchedulerTimeType(DispatchTime(uptimeNanoseconds: 1))
    let minimumTolerance: SchedulerTimeType.Stride = .zero

    private var scheduledActions: [ScheduledAction] = []
    private var lastActionId = 0

    func advance(by stride: SchedulerTimeType.Stride) {
        let deadline = now.advanced(by: stride)

        while let next = scheduledActions.filter({ $0.date <= deadline }).min(by: { ($0.date, $0.id) < ($1.date, $1.id) }) {
            scheduledActions.removeAll { $0.id == next.id }

            if let interval = next.interval {
                scheduledActions.append(ScheduledAction(id: next.id, date: next.date.advanced(by: interval), interval: interval, action: next.action))
            }

            now = next.date
            next.action()
        }

        now = deadline
    }

    func schedule(options: SchedulerOptions?, _ action: @escaping () -> Void) {
        enqueue(action, at: now, interval: nil)
    }

    func schedule(after date: SchedulerTimeType, tolerance: SchedulerTimeType.Stride, options: SchedulerOptions?, _ action: @escaping () -> Void) {
        enqueue(action, at: date, interval: nil)
    }

    func schedule(
        after date: SchedulerTimeType,
        interval: SchedulerTimeType.Stride,
        tolerance: SchedulerTimeType.Stride,
        options: SchedulerOptions?,
        _ action: @escaping () -> Void
    ) -> any Cancellable {
        ScheduledActionCancellation(scheduler: self, actionId: enqueue(action, at: date, interval: interval))
    }

    fileprivate func cancelAction(withId actionId: Int) {
        scheduledActions.removeAll { $0.id == actionId }
    }

    @discardableResult
    private func enqueue(_ action: @escaping () -> Void, at date: SchedulerTimeType, interval: SchedulerTimeType.Stride?) -> Int {
        lastActionId += 1
        scheduledActions.append(ScheduledAction(id: lastActionId, date: date, interval: interval, action: action))

        return lastActionId
    }
}

private extension ManualSchedulerStub {
    struct ScheduledAction {
        let id: Int
        let date: SchedulerTimeType
        let interval: SchedulerTimeType.Stride?
        let action: () -> Void
    }
}

private final class ScheduledActionCancellation: Cancellable {
    private weak var scheduler: ManualSchedulerStub?
    private let actionId: Int

    init(scheduler: ManualSchedulerStub, actionId: Int) {
        self.scheduler = scheduler
        self.actionId = actionId
    }

    func cancel() {
        scheduler?.cancelAction(withId: actionId)
    }
}
