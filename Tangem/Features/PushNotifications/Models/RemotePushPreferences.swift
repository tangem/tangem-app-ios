//
//  RemotePushPreferences.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct RemotePushPreferences: Equatable {
    typealias Preferences = [PushChannel: PushChannelPreference]

    private(set) var state: PushRemoteValueState<Preferences>

    init(state: PushRemoteValueState<Preferences> = .loading) {
        self.state = state
    }

    static var loading: RemotePushPreferences {
        RemotePushPreferences(state: .loading)
    }

    func preference(for channel: PushChannel) -> PushChannelPreference {
        guard case .ready(let preferences) = state,
              let preference = preferences[channel] else {
            return PushChannelPreference(isEnabled: false, isVisible: true)
        }

        return preference
    }

    /// Per-channel view of the aggregate fetch/update state.
    func remoteValueState(for channel: PushChannel) -> PushRemoteValueState<PushChannelPreference> {
        switch state {
        case .loading:
            return .loading
        case .failed:
            return .failed
        case .ready:
            return .ready(preference(for: channel))
        }
    }

    mutating func setEnabled(_ isEnabled: Bool, for channel: PushChannel) {
        var preferences = readyPreferences ?? Self.defaultPreferences
        let current = preferences[channel] ?? PushChannelPreference(isEnabled: false, isVisible: true)
        preferences[channel] = PushChannelPreference(isEnabled: isEnabled, isVisible: current.isVisible)
        state = .ready(preferences)
    }

    init(response: NotificationPreferencesDTO.Body) {
        let preferences = Dictionary(uniqueKeysWithValues: PushChannel.allCases.map { channel in
            (channel, PushChannelPreference(isEnabled: response.isEnabled(for: channel), isVisible: true))
        })
        self.init(state: .ready(preferences))
    }

    private var readyPreferences: Preferences? {
        guard case .ready(let preferences) = state else {
            return nil
        }

        return preferences
    }

    private static var defaultPreferences: Preferences {
        Dictionary(uniqueKeysWithValues: PushChannel.allCases.map {
            ($0, PushChannelPreference(isEnabled: false, isVisible: true))
        })
    }
}

extension NotificationPreferencesDTO.Body {
    init(preferences: RemotePushPreferences) {
        transactionEventsEnabled = preferences.preference(for: .transactionAlerts).isEnabled
        offerUpdatesEnabled = preferences.preference(for: .offersUpdates).isEnabled
        priceAlertsEnabled = preferences.preference(for: .priceAlerts).isEnabled
    }
}

private extension NotificationPreferencesDTO.Body {
    func isEnabled(for channel: PushChannel) -> Bool {
        switch channel {
        case .transactionAlerts: transactionEventsEnabled
        case .offersUpdates: offerUpdatesEnabled
        case .priceAlerts: priceAlertsEnabled
        }
    }
}
