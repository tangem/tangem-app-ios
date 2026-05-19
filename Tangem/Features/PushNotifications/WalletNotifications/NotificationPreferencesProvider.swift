//
//  NotificationPreferencesProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// All members are isolated to the main actor so that callers (typically SwiftUI view models)
/// never have to reason about cross-thread access to the underlying mutable state.
@MainActor
protocol NotificationPreferencesProvider: AnyObject {
    /// Remote values for each push channel received from or sent to the backend.
    var remoteStates: PushChannelRemoteStates { get }

    func remoteState(for channel: PushChannel) -> RemoteValueState<PushChannelPreference>

    /// Updates the stored remote value for a single channel.
    func setRemote(state: RemoteValueState<Bool>, for channel: PushChannel)

    /// Loads notification preferences from the backend and updates `remoteStates`.
    func fetchPreferences()

    /// Optimistically updates the cache and sends a full-replace PUT in a background task.
    /// Automatically reverts the cache to the last server-confirmed value if the request fails.
    func updatePreferences(_ preferences: [(channel: PushChannel, isEnabled: Bool)])
}
