//
//  ManualSchedulerStub.swift
//  TangemTestKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation

public final class ManualSchedulerStub: Scheduler {
    public typealias SchedulerTimeType = DispatchQueue.SchedulerTimeType
    public typealias SchedulerOptions = DispatchQueue.SchedulerOptions

    public private(set) var now = SchedulerTimeType(DispatchTime(uptimeNanoseconds: 1))
    public let minimumTolerance: SchedulerTimeType.Stride = .zero

    private var scheduledActions: [ScheduledAction] = []
    private var lastActionId = 0

    public init() {}

    public func advance(by stride: SchedulerTimeType.Stride) {
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

    public func schedule(options: SchedulerOptions?, _ action: @escaping () -> Void) {
        enqueue(action, at: now, interval: nil)
    }

    public func schedule(after date: SchedulerTimeType, tolerance: SchedulerTimeType.Stride, options: SchedulerOptions?, _ action: @escaping () -> Void) {
        enqueue(action, at: date, interval: nil)
    }

    public func schedule(
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
