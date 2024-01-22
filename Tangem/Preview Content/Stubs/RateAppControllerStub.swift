//
//  RateAppControllerStub.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

struct RateAppControllerStub: RateAppController {
    func bind(
        isPageSelectedPublisher: some Publisher<Bool, Never>,
        notificationsPublisher: some Publisher<[NotificationViewInput], Never>
    ) {}
}
