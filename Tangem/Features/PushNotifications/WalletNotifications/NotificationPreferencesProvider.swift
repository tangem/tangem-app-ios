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
    /// Emits whenever `preferences` changes (fetch, optimistic update, or rollback).
    var preferencesPublisher: AnyPublisher<RemotePushPreferences, Never> { get }

    /// Remote preferences for each push channel received from or sent to the backend.
    var preferences: RemotePushPreferences { get }

    /// Updates the stored remote value for a single channel.
    func updateRemoteEnabled(_ state: PushRemoteValueState<Bool>, for channel: PushChannel)

    /// Loads notification preferences from the backend and updates `preferences`.
    func fetchPreferences() async throws

    /// Optimistically updates the cache and sends a full-replace PUT.
    /// Reverts the cache to the last server-confirmed value if the request fails.
    func updatePreferences(isEnabled: Bool, for channel: PushChannel) async throws

    /// Enables every push channel optimistically, sends a full-replace PUT, then fetches
    /// the confirmed server state. Reverts to the last server-confirmed snapshot if the PUT fails.
    func enableAll() async throws
}
