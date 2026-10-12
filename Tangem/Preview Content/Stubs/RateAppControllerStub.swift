//
//  RateAppControllerStub.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

struct RateAppControllerStub: RateAppInteractionController, RateAppNotificationController {
    var showAppRateNotificationPublisher: AnyPublisher<Bool, Never> { .just(output: true) }

    func bind(
        notificationsPublisher1: some Publisher<[NotificationViewInput], Never>,
        notificationsPublisher2: some Publisher<[NotificationViewInput], Never>
    ) {}

    func bind(notificationsPublisher: some Publisher<[NotificationViewInput], Never>) {}

    func dismissAppRate() {}
    func openFeedbackMail() {}
    func openAppStoreReview() {}
}
