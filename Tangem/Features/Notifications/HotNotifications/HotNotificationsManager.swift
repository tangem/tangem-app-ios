//
//  HotNotificationsManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol HotNotificationsManager {
    var showFinishActivationNotificationPublisher: AnyPublisher<Bool, Never> { get }
}
