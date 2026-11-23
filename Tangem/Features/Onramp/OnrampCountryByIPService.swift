//
//  OnrampCountryByIPService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Network
import TangemExpress
import TangemFoundation

protocol OnrampCountryByIPService {
    func country(fetch: @escaping () async throws -> OnrampCountry) async throws -> OnrampCountry
}

actor CommonOnrampCountryByIPService {
    private let lifetime: TimeInterval
    private let now: () -> Date
    private let networkPathVersion: () -> Int

    private var cached: (country: OnrampCountry, fetchedAt: Date, networkPathVersion: Int)?
    private var inFlight: (task: Task<OnrampCountry, Error>, networkPathVersion: Int)?

    init(
        lifetime: TimeInterval = 60,
        now: @escaping () -> Date = Date.init,
        networkPathVersion: @escaping () -> Int
    ) {
        self.lifetime = lifetime
        self.now = now
        self.networkPathVersion = networkPathVersion
    }
}

// MARK: - OnrampCountryByIPService

extension CommonOnrampCountryByIPService: OnrampCountryByIPService {
    func country(fetch: @escaping () async throws -> OnrampCountry) async throws -> OnrampCountry {
        let requestedAt = now()
        let currentNetworkPathVersion = networkPathVersion()

        if let cached,
           cached.networkPathVersion == currentNetworkPathVersion,
           (0 ..< lifetime).contains(requestedAt.timeIntervalSince(cached.fetchedAt)) {
            return cached.country
        }

        if let inFlight, inFlight.networkPathVersion == currentNetworkPathVersion {
            return try await inFlight.task.value
        }

        let task = Task { try await fetch() }
        inFlight = (task, currentNetworkPathVersion)

        do {
            let country = try await task.value

            if inFlight?.task == task {
                cached = (country, now(), currentNetworkPathVersion)
                inFlight = nil
            }

            return country
        } catch {
            if inFlight?.task == task {
                inFlight = nil
            }

            throw error
        }
    }
}

// MARK: - Network path changes

final class OnrampNetworkPathVersion: Sendable {
    private struct State {
        var version = 0
        var lastPath: NWPath?
    }

    private let monitor = NWPathMonitor()
    private let state = OSAllocatedUnfairLock(initialState: State())

    var current: Int {
        state.withLock { $0.version }
    }

    init() {
        monitor.pathUpdateHandler = { [state] path in
            state.withLock { state in
                if let lastPath = state.lastPath, lastPath != path {
                    state.version += 1
                }

                state.lastPath = path
            }
        }
        monitor.start(queue: DispatchQueue(label: "com.tangem.onramp.country-by-ip.network-path"))
    }

    deinit {
        monitor.cancel()
    }
}

// MARK: - Injection

private struct OnrampCountryByIPServiceKey: InjectionKey {
    static var currentValue: OnrampCountryByIPService = {
        let networkPathVersion = OnrampNetworkPathVersion()
        return CommonOnrampCountryByIPService(networkPathVersion: { networkPathVersion.current })
    }()
}

extension InjectedValues {
    var onrampCountryByIPService: OnrampCountryByIPService {
        get { Self[OnrampCountryByIPServiceKey.self] }
        set { Self[OnrampCountryByIPServiceKey.self] = newValue }
    }
}
