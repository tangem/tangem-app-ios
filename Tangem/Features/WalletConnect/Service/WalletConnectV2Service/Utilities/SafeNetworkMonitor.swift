//
//  SafeNetworkMonitor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Network
import Combine
import WalletConnectRelay

/// A safe replacement for the library's internal `NetworkMonitor`.
///
/// The library's `WalletPairService.resolveNetworkConnectionStatus()` subscribes to
/// `networkConnectionStatusPublisher` and resumes a `CheckedContinuation` on every emission.
/// The subscription is cancelled asynchronously via a separate `Task`, creating a race window
/// where rapid `NWPathMonitor` re-evaluations can cause the continuation to be resumed twice,
/// triggering a fatal crash.
///
/// This implementation:
/// - emits the current value immediately (to preserve library behavior),
/// - debounces subsequent monitor updates to outlive the cancellation race window,
/// - removes duplicate statuses.
final class SafeNetworkMonitor: NetworkMonitoring {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.tangem.wc.safe-network-monitor")
    private let subject = CurrentValueSubject<NetworkConnectionStatus, Never>(.connected)
    private let updatesDebounceInterval = DispatchQueue.SchedulerTimeType.Stride.milliseconds(300)

    var isConnected: Bool {
        subject.value == .connected
    }

    var networkConnectionStatusPublisher: AnyPublisher<NetworkConnectionStatus, Never> {
        subject
            .dropFirst()
            .debounce(for: updatesDebounceInterval, scheduler: queue)
            .prepend(subject.value)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.subject.send(path.status == .satisfied ? .connected : .notConnected)
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.pathUpdateHandler = nil
        monitor.cancel()
    }
}
