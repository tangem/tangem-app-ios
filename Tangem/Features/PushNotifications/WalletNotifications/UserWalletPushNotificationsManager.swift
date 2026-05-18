//
//  UserWalletPushNotificationsManager.swift
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

    /// Returns true if remote status is enabled on backend
    /// Used to determine if permission warning should be shown
    var isRemoteStatusEnabled: Bool { get }

    func handleUpdateOnRemoteStatus(_ status: UserWalletPushNotifyRemoteStatus)
    func handleUpdateOnLocalStatus(_ isEnabled: Bool)
    func handleSyncError()

    func getInitialPushStatusWithAllowance() async -> Bool
}
