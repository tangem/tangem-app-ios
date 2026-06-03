//
//  NotificationManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol NotificationManager: AnyObject {
    var notificationInputs: [NotificationViewInput] { get async }
    var notificationPublisher: AnyPublisher<[NotificationViewInput], Never> { get }

    func setupManager(with delegate: NotificationTapDelegate?)
    func dismissNotification(with id: NotificationViewId)
}
