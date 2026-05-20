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

    func updateRemoteEnabled(_ state: PushRemoteValueState<Bool>, for channel: PushChannel) {
        switch state {
        case .loading:
            remoteStatesSubject.send(.allLoading)
        case .failed:
            remoteStatesSubject.send(PushChannelRemoteStates(loadState: .failed))
        case .ready(let isEnabled):
            var states = remoteStatesSubject.value
            states.setEnabled(isEnabled, for: channel)
            remoteStatesSubject.send(states)
        }
    }

    func fetchPreferences() async throws {}

    func updatePreferences(isEnabled: Bool, for channel: PushChannel) async throws {}
}
