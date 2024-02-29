//
//  FakeSendNotificationManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class FakeSendNotificationManager: FakeUserWalletNotificationManager, SendNotificationManager {
    func notificationPublisher(for location: SendNotificationEvent.Location) -> AnyPublisher<[NotificationViewInput], Never> {
        .just(output: [])
    }

    func hasNotifications(with severity: NotificationView.Severity) -> AnyPublisher<Bool, Never> {
        .just(output: false)
    }
}
