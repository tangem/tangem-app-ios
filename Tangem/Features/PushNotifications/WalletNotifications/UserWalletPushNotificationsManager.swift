//
//  UserWalletPushNotificationsManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol UserWalletPushNotificationsManager {
    /// Emits the current per-channel preference state whenever it changes (fetch, optimistic
    /// update, or rollback). Consumers can use `RemotePushPreferences.remoteValueState(for:)`
    /// to extract a single channel's `PushRemoteValueState<PushChannelPreference>`.
    var preferencesPublisher: AnyPublisher<RemotePushPreferences, Never> { get }

    /// The latest per-channel preference snapshot — a synchronous read of the value
    /// `preferencesPublisher` currently holds.
    var preferences: RemotePushPreferences { get }

    /// Handles a push-notification event and updates internal manager state accordingly.
    func process(_ event: UserWalletPushNotificationsEvent)

    /// User toggled the switch for the given channel (UI intent).
    /// Optimistically updates the backend preference and throws on failure so the caller can revert UI and surface an error.
    func tryUpdateEnableState(value: Bool, for channel: PushChannel) async throws

    /// Re-requests channel preferences from the backend (e.g. the settings screen's retry action
    /// after a failed load). The result is delivered through `preferencesPublisher`.
    func refetchPreferences() async throws
}

/// Events that drive push-notification preference transitions. Callers post these
/// through `process(_:)` instead of invoking dedicated handler methods; the manager
/// owns the fan-out into the preferences fetch and any downstream backend resync.
enum UserWalletPushNotificationsEvent: Equatable {
    /// Triggers a manager-side preferences fetch after wallet binding with application sync.
    case walletApplicationBindingSynchronized
    /// Push sync cannot proceed because wallet/application binding info is unavailable.
    case walletBindingInfoUnavailable
}
