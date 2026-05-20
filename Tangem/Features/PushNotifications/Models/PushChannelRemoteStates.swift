//
//  PushChannelRemoteStates.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct PushChannelRemoteStates: Equatable {
    typealias Preferences = [PushChannel: PushChannelPreference]

    private(set) var loadState: PushRemoteValueState<Preferences>

    init(loadState: PushRemoteValueState<Preferences> = .loading) {
        self.loadState = loadState
    }

    static var allLoading: PushChannelRemoteStates {
        PushChannelRemoteStates(loadState: .loading)
    }

    func preference(for channel: PushChannel) -> PushChannelPreference {
        guard case .ready(let preferences) = loadState,
              let preference = preferences[channel] else {
            return PushChannelPreference(isEnabled: false, isVisible: true)
        }

        return preference
    }

    mutating func setEnabled(_ isEnabled: Bool, for channel: PushChannel) {
        var preferences = readyPreferences ?? Self.defaultPreferences
        let current = preferences[channel] ?? PushChannelPreference(isEnabled: false, isVisible: true)
        preferences[channel] = PushChannelPreference(isEnabled: isEnabled, isVisible: current.isVisible)
        loadState = .ready(preferences)
    }

    private var readyPreferences: Preferences? {
        guard case .ready(let preferences) = loadState else {
            return nil
        }

        return preferences
    }

    init(response: NotificationPreferencesDTO.Response.Body) {
        let preferences = Dictionary(uniqueKeysWithValues: PushChannel.allCases.map { channel in
            let preference = response.preference(for: channel)
            return (
                channel,
                PushChannelPreference(isEnabled: preference.isEnabled, isVisible: preference.isVisible)
            )
        })
        self.init(loadState: .ready(preferences))
    }

    private static var defaultPreferences: Preferences {
        Dictionary(uniqueKeysWithValues: PushChannel.allCases.map {
            ($0, PushChannelPreference(isEnabled: false, isVisible: true))
        })
    }
}

extension NotificationPreferencesDTO.Update.Request {
    init(remoteStates: PushChannelRemoteStates) {
        transactionAlerts = remoteStates.preference(for: .transactionAlerts).isEnabled
        offersUpdates = remoteStates.preference(for: .offersUpdates).isEnabled
        priceAlerts = remoteStates.preference(for: .priceAlerts).isEnabled
    }
}
