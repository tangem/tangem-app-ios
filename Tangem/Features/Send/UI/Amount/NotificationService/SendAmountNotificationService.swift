//
//  SendAmountNotificationService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

protocol SendAmountNotificationService {
    var notificationMessagePublisher: AnyPublisher<String?, Never> { get }
}
