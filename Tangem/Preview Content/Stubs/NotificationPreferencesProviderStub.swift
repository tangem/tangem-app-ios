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
    private let remoteStatesSubject = CurrentValueSubject<PushChannelRemoteStates, Never>(.allLoading)

    var remoteStatesPublisher: AnyPublisher<PushChannelRemoteStates, Never> {
        remoteStatesSubject.eraseToAnyPublisher()
    }

    var remoteStates: PushChannelRemoteStates {
        remoteStatesSubject.value
    }

    init() {}

    func updateRemoteEnabled(_ state: RemoteValueState<Bool>, for channel: PushChannel) {
        var states = remoteStatesSubject.value
        let visibility = states.preference(for: channel).isVisible

        switch state {
        case .loading:
            states[channel] = .loading
        case .failed:
            states[channel] = .failed
        case .pending(let isEnabled):
            states[channel] = .pending(PushChannelPreference(isEnabled: isEnabled, isVisible: visibility))
        case .ready(let isEnabled):
            states[channel] = .ready(PushChannelPreference(isEnabled: isEnabled, isVisible: visibility))
        }

        remoteStatesSubject.send(states)
    }

    func fetchPreferences() {}

    func updatePreferences(_ preferences: [(channel: PushChannel, isEnabled: Bool)]) {
        var states = remoteStatesSubject.value

        for (channel, isEnabled) in preferences {
            states.setPendingEnabled(isEnabled, for: channel)
        }

        remoteStatesSubject.send(states.settlingPendingToReady())
    }
}
