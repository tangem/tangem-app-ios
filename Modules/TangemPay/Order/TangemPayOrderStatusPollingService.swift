//
//  TangemPayOrderStatusPollingService.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

public final class TangemPayOrderStatusPollingService {
    private struct ActiveTask {
        let id: UUID
        let task: Task<Void, Never>
    }

    private enum PollOutcome {
        case completed
        case canceled
        case failed(Error)
    }

    private let customerService: CustomerInfoManagementService

    private var orderStatusPollingTasks: [String: ActiveTask] = [:]
    private let lock = NSLock()

    public init(customerService: CustomerInfoManagementService) {
        self.customerService = customerService
    }

    public func startOrderStatusPolling(
        orderId: String,
        interval: TimeInterval,
        onCompleted: @escaping () -> Void,
        onCanceled: @escaping () -> Void,
        onFailed: @escaping (Error) -> Void,
        onProgress: ((TangemPayOrderResponse) -> Void)? = nil
    ) {
        lock.lock()

        if orderStatusPollingTasks[orderId] != nil {
            lock.unlock()
            return
        }

        let taskId = UUID()
        let polling = PollingSequence(
            interval: interval,
            request: { [customerService] in
                try await customerService.getOrder(orderId: orderId)
            }
        )

        let task = runTask { [weak self] in
            let outcome = await Self.runPolling(polling, onProgress: onProgress)
            self?.removeTask(orderId: orderId, taskId: taskId)
            switch outcome {
            case .completed:
                onCompleted()
            case .canceled:
                onCanceled()
            case .failed(let error):
                onFailed(error)
            }
        }

        orderStatusPollingTasks[orderId] = ActiveTask(id: taskId, task: task)
        lock.unlock()
    }

    public func cancelAll() {
        lock.lock()
        let tasks = orderStatusPollingTasks
        orderStatusPollingTasks.removeAll()
        lock.unlock()
        for entry in tasks.values {
            entry.task.cancel()
        }
    }

    /// Cancels polling for a specific orderId. The task's terminal callback (`onCanceled`)
    /// will still fire — callers that no longer want side effects (e.g. failure alerts)
    /// must guard those callbacks themselves.
    public func cancel(orderId: String) {
        lock.lock()
        let entry = orderStatusPollingTasks.removeValue(forKey: orderId)
        lock.unlock()
        entry?.task.cancel()
    }

    /// Removes the dict entry only if its task identity matches `taskId`. Prevents a canceled
    /// task's deferred cleanup from evicting a freshly-started replacement at the same `orderId`.
    private func removeTask(orderId: String, taskId: UUID) {
        lock.lock()
        defer { lock.unlock() }
        if orderStatusPollingTasks[orderId]?.id == taskId {
            orderStatusPollingTasks.removeValue(forKey: orderId)
        }
    }

    private static func runPolling(
        _ polling: PollingSequence<TangemPayOrderResponse>,
        onProgress: ((TangemPayOrderResponse) -> Void)?
    ) async -> PollOutcome {
        for await result in polling {
            switch result {
            case .success(let order):
                switch order.status {
                case .new, .processing:
                    onProgress?(order)
                    continue
                case .completed:
                    return .completed
                case .canceled:
                    return .canceled
                case .failed, .undefined:
                    return .failed(TangemPayOrderStatusPollingError.terminalStatus(order.status))
                }
            case .failure:
                continue
            }
        }
        return .canceled
    }

    deinit {
        cancelAll()
    }
}

public enum TangemPayOrderStatusPollingError: Error {
    case terminalStatus(TangemPayOrderResponse.Status)
}
