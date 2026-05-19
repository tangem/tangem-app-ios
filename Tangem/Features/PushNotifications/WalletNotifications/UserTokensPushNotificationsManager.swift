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

    var isNotInitialized: Bool { get }

    /// True when the permission warning row should be visible — i.e., push notifications
    /// are enabled on the backend but the iOS system permission is not granted.
    var shouldShowPermissionWarning: Bool { get }

    func dispatch(_ event: UserTokensPushEvent)

    func getInitialPushStatusWithAllowance() async -> Bool
}

/// Events that drive push-notification status transitions. Callers post these
/// through `dispatch(_:)` instead of invoking dedicated handler methods; the manager
/// owns the fan-out into remote-subject updates, status recomputation, and any
/// downstream backend resync.
enum UserTokensPushEvent {
    /// Remote status was fetched or refreshed (e.g., during initial sync or after
    /// a backend response).
    case remoteStatusUpdated(RemoteValueState<Bool>)
    /// User toggled the local switch (UI intent).
    case localStatusUpdated(Bool)
    /// Backend sync failed.
    case syncFailed
}
