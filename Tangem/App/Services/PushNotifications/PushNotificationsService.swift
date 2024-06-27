//
//  PushNotificationsService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol PushNotificationsService {
    // [REDACTED_TODO_COMMENT]
    // https://forums.swift.org/t/use-a-protocol-of-mainactor-instead-of-concrete-mainactor-class-produces-an-error/72542
    /*@MainActor*/
    var isAvailable: Bool { get async }
}
