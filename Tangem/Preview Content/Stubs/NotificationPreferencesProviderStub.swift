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

    nonisolated init() {}

    func updateRemoteEnabled(_ state: PushRemoteValueState<Bool>, for channel: PushChannel) {
        var states = remoteStatesSubject.value
        let visibility = states.preference(for: channel).isVisible

        switch state {
        case .loading:
            states[channel] = .loading
        case .failed:
            states[channel] = .failed
        case .ready(let isEnabled):
            states[channel] = .ready(PushChannelPreference(isEnabled: isEnabled, isVisible: visibility))
        }

        remoteStatesSubject.send(states)
    }

    func fetchPreferences() {}

    func updatePreferences(_ preferences: [(channel: PushChannel, isEnabled: Bool)]) {}
}
