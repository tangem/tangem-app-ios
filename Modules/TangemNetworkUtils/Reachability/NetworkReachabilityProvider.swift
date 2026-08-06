//
//  NetworkReachabilityProvider.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

/// A source of network reachability state.
///
/// - Warning: Reachability only reflects whether a network interface is available for routing.
/// A `reachable` state doesn't guarantee that requests will succeed (captive portals, DNS issues, etc.),
/// so it must be used as a hint for scheduling work, never as a gate that replaces error handling.
public protocol NetworkReachabilityProvider: Sendable {
    /// A snapshot of the current reachability state.
    var isReachable: Bool { get }

    /// Emits the current state immediately on subscription, then every state change.
    var isReachablePublisher: AnyPublisher<Bool, Never> { get }
}
