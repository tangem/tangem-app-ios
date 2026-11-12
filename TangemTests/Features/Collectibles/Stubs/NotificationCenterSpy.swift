//
//  NotificationCenterSpy.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import TangemFoundation

final class NotificationCenterSpy: NotificationCenter, @unchecked Sendable {
    private struct Waiter {
        let name: Notification.Name
        let continuation: CheckedContinuation<Void, any Error>
    }

    private struct State {
        var observedNames: Set<Notification.Name> = []
        var waiters: [UUID: Waiter] = [:]
    }

    private let state = OSAllocatedUnfairLock(initialState: State())

    func observation(of event: AppEvent) async throws {
        let id = UUID()

        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
                let outcome = state.withLock { state -> Result<Void, any Error>? in
                    if Task.isCancelled {
                        return .failure(CancellationError())
                    }

                    guard !state.observedNames.contains(event.name) else {
                        return .success(())
                    }

                    state.waiters[id] = Waiter(name: event.name, continuation: continuation)
                    return nil
                }

                if let outcome {
                    continuation.resume(with: outcome)
                }
            }
        } onCancel: {
            state.withLock { $0.waiters.removeValue(forKey: id) }?.continuation.resume(throwing: CancellationError())
        }
    }

    override func addObserver(
        forName name: NSNotification.Name?,
        object obj: Any?,
        queue: OperationQueue?,
        using block: @escaping @Sendable (Notification) -> Void
    ) -> any NSObjectProtocol {
        let observer = super.addObserver(forName: name, object: obj, queue: queue, using: block)

        guard let name else {
            return observer
        }

        let waiters = state.withLock { state -> [Waiter] in
            state.observedNames.insert(name)
            let waiters = state.waiters.filter { $0.value.name == name }
            waiters.keys.forEach { state.waiters.removeValue(forKey: $0) }
            return Array(waiters.values)
        }

        waiters.forEach { $0.continuation.resume() }

        return observer
    }
}

extension NotificationCenter {
    enum AppEvent {
        case didEnterBackground
        case willEnterForeground

        var name: Notification.Name {
            switch self {
            case .didEnterBackground: UIApplication.didEnterBackgroundNotification
            case .willEnterForeground: UIApplication.willEnterForegroundNotification
            }
        }
    }

    func post(_ event: AppEvent) {
        post(name: event.name, object: nil)
    }

    @MainActor
    func postAndWaitForDelivery(_ event: AppEvent) async throws {
        let released = TestSignal<Void>()

        autoreleasepool {
            post(name: event.name, object: ReleaseSignal { released.send() })
        }

        try await released.next()
    }
}

private final class ReleaseSignal: Sendable {
    private let onRelease: @Sendable () -> Void

    init(onRelease: @escaping @Sendable () -> Void) {
        self.onRelease = onRelease
    }

    deinit {
        onRelease()
    }
}
