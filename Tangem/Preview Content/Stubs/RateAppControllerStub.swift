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
    var showAppRateNotificationPublisher: AnyPublisher<Bool, Never> { fatalError() }

    func bind(
        isPageSelectedPublisher: some Publisher<Bool, Never>,
        notificationsPublisher1: some Publisher<[NotificationViewInput], Never>,
        notificationsPublisher2: some Publisher<[NotificationViewInput], Never>
    ) {}

    func bind(
        isPageSelectedPublisher: some Publisher<Bool, Never>,
        notificationsPublisher: some Publisher<[NotificationViewInput], Never>
    ) {}

    func dismissAppRate() {}
    func openFeedbackMail(with emailType: EmailType) {}
    func openAppStoreReview() {}
}
