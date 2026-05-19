//
//  UserTokensPushNotificationsManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol UserTokensPushNotificationsManager {
    var statusPublisher: AnyPublisher<UserWalletPushNotifyStatus, Never> { get }
    var status: UserWalletPushNotifyStatus { get }

    /// True when the permission warning row should be visible — i.e., push notifications
    /// are enabled on the backend but the iOS system permission is not granted.
    var shouldShowPermissionWarning: Bool { get }

    /// Handles a push-status event and updates internal manager state accordingly.
    func dispatch(_ event: UserTokensPushEvent)

    /// Returns the effective initial push-enabled flag with allowance fallback applied.
    func getInitialPushStatusWithAllowance() async -> Bool
}

/// Events that drive push-notification status transitions. Callers post these
/// through `dispatch(_:)` instead of invoking dedicated handler methods; the manager
/// owns the fan-out into remote-subject updates, status recomputation, and any
/// downstream backend resync.
enum UserTokensPushEvent {
    /// Triggers manager-side status synchronization after wallet binding with application sync.
    case walletBindingWithApplicationSynchronized
    /// Push sync cannot proceed because wallet/application binding info is unavailable.
    case walletsBindingInfoUnavailable
    /// Remote status was fetched or refreshed (e.g., during initial sync or after
    /// a backend response).
    case didReceiveRemoteStatus(RemoteValueState<Bool>)
    /// User toggled the local switch (UI intent).
    case didChangeLocalStatus(Bool)
}
