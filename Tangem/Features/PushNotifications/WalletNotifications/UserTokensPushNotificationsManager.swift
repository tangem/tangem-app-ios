//
//  UserTokensPushNotificationsManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

// [REDACTED_TODO_COMMENT]
protocol UserTokensPushNotificationsManager {
    @available(iOS, deprecated: 100000.0, message: "Will be removed after full migration to channel-based push notifications.")
    var statusPublisher: AnyPublisher<UserWalletPushNotifyStatus, Never> { get }
    @available(iOS, deprecated: 100000.0, message: "Will be removed after full migration to channel-based push notifications.")
    var status: UserWalletPushNotifyStatus { get }

    /// Emits the current per-channel preference state whenever it changes (fetch, optimistic
    /// update, or rollback). Consumers can use `RemotePushPreferences.remoteValueState(for:)`
    /// to extract a single channel's `PushRemoteValueState<PushChannelPreference>`.
    var preferencesPublisher: AnyPublisher<RemotePushPreferences, Never> { get }

    /// Displayed last synced remote status on backend
    var isRemoteStatusEnabled: Bool { get }

    /// Handles a push-status event and updates internal manager state accordingly.
    func process(_ event: UserWalletPushNotificationsEvent)

    /// User toggled the switch for the given channel (UI intent).
    /// Optimistically updates the backend preference and throws on failure so
    /// the caller can revert UI and surface an error.
    func tryUpdateEnableState(value: Bool, for channel: PushChannel) async throws

    /// Whether remote `notifyStatus` should be forced to `true` on first sync because system
    /// push permission is granted and this wallet has not completed allowance onboarding yet.
    func shouldAllowanceRemoteNotifyStatus() async -> Bool
}

/// Events that drive push-notification status transitions. Callers post these
/// through `process(_:)` instead of invoking dedicated handler methods; the manager
/// owns the fan-out into remote-subject updates, status recomputation, and any
/// downstream backend resync.
enum UserWalletPushNotificationsEvent: Equatable {
    /// Triggers manager-side status synchronization after wallet binding with application sync.
    case walletApplicationBindingSynchronized
    /// Push sync cannot proceed because wallet/application binding info is unavailable.
    case walletBindingInfoUnavailable
    /// Remote status was fetched or refreshed (e.g., during initial sync or after
    /// a backend response).
    case remoteStatusReceived(Bool, PushChannel)
}
