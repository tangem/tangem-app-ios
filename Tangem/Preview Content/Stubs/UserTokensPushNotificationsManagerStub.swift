//
//  UserTokensPushNotificationsManagerStub.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

struct UserTokensPushNotificationsManagerStub: UserTokensPushNotificationsManager {
    var statusPublisher: AnyPublisher<UserWalletPushNotifyStatus, Never> { .just(output: status) }
    var status: UserWalletPushNotifyStatus { .disabled }
    func handleUpdateWalletPushNotifyStatus(_ status: UserWalletPushNotifyStatus) {}
}
