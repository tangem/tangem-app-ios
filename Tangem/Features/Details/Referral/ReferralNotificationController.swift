//
//  ReferralNotificationController.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol ReferralNotificationController {
    var showReferralNotificationPublisher: AnyPublisher<Bool?, Never> { get }

    func checkReferralStatus()
    func dismissReferralNotification()
}
