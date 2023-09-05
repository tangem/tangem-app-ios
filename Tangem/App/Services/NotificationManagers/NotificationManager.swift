//
//  NotificationManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol NotificationManager {
    var notificationPublisher: AnyPublisher<[NotificationViewInput], Never> { get }

    func dismissNotification(with id: NotificationViewId)
}
