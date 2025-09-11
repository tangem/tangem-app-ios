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

    func handleUpdateWalletPushNotifyStatus(_ status: UserWalletPushNotifyStatus)
}
