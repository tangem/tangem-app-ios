//
//  PushChannelRemoteStates.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct PushChannelRemoteStates: Equatable {
    private(set) var states: [PushChannel: RemoteValueState<PushChannelPreference>]

    init(states: [PushChannel: RemoteValueState<PushChannelPreference>] = [:]) {
        self.states = states
    }

    static var allLoading: PushChannelRemoteStates {
        PushChannelRemoteStates(
            states: Dictionary(uniqueKeysWithValues: PushChannel.allCases.map { ($0, .loading) })
        )
    }

    subscript(channel: PushChannel) -> RemoteValueState<PushChannelPreference> {
        get { states[channel] ?? .loading }
        set { states[channel] = newValue }
    }

    init(response: NotificationPreferencesDTO.Response.Body) {
        self.init(
            states: Dictionary(uniqueKeysWithValues: PushChannel.allCases.map { channel in
                let preference = response.preference(for: channel)
                return (
                    channel,
                    .ready(PushChannelPreference(isEnabled: preference.isEnabled, isVisible: preference.isVisible))
                )
            })
        )
    }

    func preference(for channel: PushChannel) -> PushChannelPreference {
        guard case .ready(let preference) = self[channel] else {
            return PushChannelPreference(isEnabled: false, isVisible: true)
        }

        return preference
    }

    mutating func setEnabled(_ isEnabled: Bool, for channel: PushChannel) {
        let current = preference(for: channel)
        self[channel] = .ready(PushChannelPreference(isEnabled: isEnabled, isVisible: current.isVisible))
    }
}

extension NotificationPreferencesDTO.Update.Request {
    init(remoteStates: PushChannelRemoteStates) {
        transactionAlerts = remoteStates.preference(for: .transactionAlerts).isEnabled
        offersUpdates = remoteStates.preference(for: .offersUpdates).isEnabled
        priceAlerts = remoteStates.preference(for: .priceAlerts).isEnabled
    }
}
