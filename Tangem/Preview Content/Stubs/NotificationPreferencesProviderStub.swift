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
    private let preferencesSubject = CurrentValueSubject<RemotePushPreferences, Never>(.loading)

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
            preferencesSubject.send(updated)
        }
    }

    func fetchPreferences() async throws {}

    func updatePreferences(isEnabled: Bool, for channel: PushChannel) async throws {}
}
