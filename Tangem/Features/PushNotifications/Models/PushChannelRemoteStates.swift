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
        switch self[channel] {
        case .ready(let preference), .pending(let preference):
            return preference
        case .loading, .failed:
            return PushChannelPreference(isEnabled: false, isVisible: true)
        }
    }

    mutating func setPendingEnabled(_ isEnabled: Bool, for channel: PushChannel) {
        let visibility = preference(for: channel).isVisible
        self[channel] = .pending(PushChannelPreference(isEnabled: isEnabled, isVisible: visibility))
    }

    func settlingPendingToReady() -> PushChannelRemoteStates {
        var settled = self

        for channel in PushChannel.allCases {
            guard case .pending(let preference) = settled[channel] else {
                continue
            }

            settled[channel] = .ready(preference)
        }

        return settled
    }
}

extension NotificationPreferencesDTO.Update.Request {
    init(remoteStates: PushChannelRemoteStates) {
        transactionAlerts = remoteStates.preference(for: .transactionAlerts).isEnabled
        offersUpdates = remoteStates.preference(for: .offersUpdates).isEnabled
        priceAlerts = remoteStates.preference(for: .priceAlerts).isEnabled
    }
}
