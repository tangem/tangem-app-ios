//
//  HotNotificationsController.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol HotNotificationsController {
    var showFinishActivationNotificationPublisher: AnyPublisher<Bool, Never> { get }
}
