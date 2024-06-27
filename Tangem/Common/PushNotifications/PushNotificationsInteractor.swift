//
//  PushNotificationsInteractor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol PushNotificationsInteractor {
    var isAvailable: Bool { get async }

    func allowRequest()
    func postponeRequest()
}
