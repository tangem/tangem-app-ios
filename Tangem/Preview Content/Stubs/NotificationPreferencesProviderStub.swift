//
//  NotificationPreferencesProviderStub.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

@MainActor
final class NotificationPreferencesProviderStub: NotificationPreferencesProvider {
    var remoteStates: PushChannelRemoteStates = .allLoading

    nonisolated init() {}

    func remoteState(for channel: PushChannel) -> RemoteValueState<PushChannelPreference> {
        remoteStates[channel]
    }

    func setRemoteState(_ state: RemoteValueState<PushChannelPreference>, for channel: PushChannel) {
        remoteStates[channel] = state
    }

    func fetchPreferences() {}

    func updatePreferences(_ preferences: [(channel: PushChannel, isEnabled: Bool)]) {}
}
