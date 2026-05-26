//
//  NotificationPreferencesProviderStub.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class NotificationPreferencesProviderStub: NotificationPreferencesProvider {
    // MARK: - Private Properties

    private let preferencesSubject = CurrentValueSubject<RemotePushPreferences, Never>(.loading)

    /// In-memory store that acts as the "server" state. Populated on first `fetchPreferences` call.
    private var serverPreferences: RemotePushPreferences.Preferences?

    private static let simulatedNetworkDelay: Duration = .milliseconds(500)

    // MARK: - NotificationPreferencesProvider

    var preferencesPublisher: AnyPublisher<RemotePushPreferences, Never> {
        preferencesSubject.eraseToAnyPublisher()
    }

    var preferences: RemotePushPreferences {
        preferencesSubject.value
    }

    init() {}

    func updateRemoteEnabled(_ state: PushRemoteValueState<Bool>, for channel: PushChannel) {
        switch state {
        case .loading:
            preferencesSubject.send(.loading)
        case .failed:
            preferencesSubject.send(RemotePushPreferences(state: .failed))
        case .ready(let isEnabled):
            var updated = preferencesSubject.value
            updated.setEnabled(isEnabled, for: channel)
            serverPreferences?[channel] = PushChannelPreference(isEnabled: isEnabled, isVisible: true)
            preferencesSubject.send(updated)
        }
    }

    func fetchPreferences() async throws {
        try await Task.sleep(for: Self.simulatedNetworkDelay)

        if serverPreferences == nil {
            serverPreferences = Self.makeRandomPreferences()
        }

        let loaded = RemotePushPreferences(state: .ready(serverPreferences!))
        preferencesSubject.send(loaded)
    }

    func updatePreferences(isEnabled: Bool, for channel: PushChannel) async throws {
        let snapshot = preferencesSubject.value

        // Optimistic update
        var optimistic = snapshot
        optimistic.setEnabled(isEnabled, for: channel)
        preferencesSubject.send(optimistic)

        do {
            try await Task.sleep(for: Self.simulatedNetworkDelay)
            serverPreferences?[channel] = PushChannelPreference(isEnabled: isEnabled, isVisible: true)
        } catch {
            // Rollback on cancellation
            preferencesSubject.send(snapshot)
            throw error
        }
    }

    func enableAll() async throws {
        let snapshot = preferencesSubject.value

        var optimistic = snapshot
        for channel in PushChannel.allCases {
            optimistic.setEnabled(true, for: channel)
        }
        preferencesSubject.send(optimistic)

        do {
            try await Task.sleep(for: Self.simulatedNetworkDelay)

            for channel in PushChannel.allCases {
                let current = serverPreferences?[channel] ?? PushChannelPreference(isEnabled: false, isVisible: true)
                serverPreferences?[channel] = PushChannelPreference(isEnabled: true, isVisible: current.isVisible)
            }
        } catch {
            preferencesSubject.send(snapshot)
            throw error
        }
    }
}

// MARK: - Private Helpers

private extension NotificationPreferencesProviderStub {
    static func makeRandomPreferences() -> RemotePushPreferences.Preferences {
        Dictionary(uniqueKeysWithValues: PushChannel.allCases.map { channel in
            (channel, PushChannelPreference(isEnabled: Bool.random(), isVisible: true))
        })
    }
}
