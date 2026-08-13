//
//  CommonNetworkReachabilityProvider.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Alamofire

/// A `NetworkReachabilityProvider` backed by Alamofire's `NetworkReachabilityManager`.
///
/// `Alamofire.NetworkReachabilityManager` supports a single listener (`startListening` replaces the previous
/// one), so the manager instance is private to this provider and the subject fans its state out to every
/// subscriber.
///
/// - Note: The subject synchronizes internally, so the type is marked `@unchecked Sendable`.
public final class CommonNetworkReachabilityProvider: @unchecked Sendable {
    private let subject: CurrentValueSubject<Bool, Never>
    private let manager = NetworkReachabilityManager()
    private let listenerQueue = DispatchQueue(label: "com.tangem.network-reachability-provider")

    public init() {
        // The `unknown` state is treated as reachable: it's better to attempt a request and fail than to hold
        // it back based on an inconclusive signal.
        subject = CurrentValueSubject(manager?.status != .notReachable)

        manager?.startListening(onQueue: listenerQueue) { [subject] status in
            subject.send(status != .notReachable)
        }
    }

    deinit {
        manager?.stopListening()
    }
}

// MARK: - NetworkReachabilityProvider

extension CommonNetworkReachabilityProvider: NetworkReachabilityProvider {
    public var isReachable: Bool {
        subject.value
    }

    /// The manager notifies on any status change, including transitions between two reachable connection types
    /// (Wi-Fi <-> cellular), so consecutive duplicates are filtered out here.
    public var isReachablePublisher: AnyPublisher<Bool, Never> {
        subject.removeDuplicates().eraseToAnyPublisher()
    }
}
