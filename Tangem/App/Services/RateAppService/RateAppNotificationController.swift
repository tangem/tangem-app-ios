//
//  RateAppNotificationController.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol RateAppNotificationController {
    var showAppRateNotificationPublisher: AnyPublisher<Bool, Never> { get }

    func dismissAppRate()
}
