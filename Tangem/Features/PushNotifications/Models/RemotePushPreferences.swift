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

    init(response: NotificationPreferencesDTO.Response.Body) {
        let preferences = Dictionary(uniqueKeysWithValues: PushChannel.allCases.map { channel in
            let preference = response.preference(for: channel)
            return (
                channel,
                PushChannelPreference(isEnabled: preference.isEnabled, isVisible: preference.isVisible)
            )
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

extension NotificationPreferencesDTO.Update.Request {
    init(preferences: RemotePushPreferences) {
        transactionAlerts = preferences.preference(for: .transactionAlerts).isEnabled
        offersUpdates = preferences.preference(for: .offersUpdates).isEnabled
        priceAlerts = preferences.preference(for: .priceAlerts).isEnabled
    }
}

private extension NotificationPreferencesDTO.Response.Body {
    func preference(for channel: PushChannel) -> NotificationPreferencesDTO.Preference {
        switch channel {
        case .transactionAlerts: transactionAlerts
        case .offersUpdates: offersUpdates
        case .priceAlerts: priceAlerts
        }
    }
}
