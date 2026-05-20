//
//  NotificationPreferencesProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// Abstraction for reading and updating push-notification channel preferences.
protocol NotificationPreferencesProvider: AnyObject {
    /// Emits whenever `remoteStates` changes (fetch, optimistic update, or rollback).
    var remoteStatesPublisher: AnyPublisher<PushChannelRemoteStates, Never> { get }

    /// Remote values for each push channel received from or sent to the backend.
    var remoteStates: PushChannelRemoteStates { get }

    /// Updates the stored remote value for a single channel.
    func updateRemoteEnabled(_ state: PushRemoteValueState<Bool>, for channel: PushChannel)

    /// Loads notification preferences from the backend and updates `remoteStates`.
    func fetchPreferences() async throws

    /// Optimistically updates the cache and sends a full-replace PUT.
    /// Reverts the cache to the last server-confirmed value if the request fails.
    func updatePreferences(isEnabled: Bool, for channel: PushChannel) async throws
}
