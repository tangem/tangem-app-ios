//
//  RateAppController.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol RateAppController {
    var showAppRateNotificationPublisher: AnyPublisher<Bool, Never> { get }

    func bind(
        isPageSelectedPublisher: some Publisher<Bool, Never>,
        notificationsPublisher1: some Publisher<[NotificationViewInput], Never>,
        notificationsPublisher2: some Publisher<[NotificationViewInput], Never>
    )

    func bind(
        isPageSelectedPublisher: some Publisher<Bool, Never>,
        notificationsPublisher: some Publisher<[NotificationViewInput], Never>
    )

    @available(*, deprecated, message: "Test only")
    func dismissAppRate()

    @available(*, deprecated, message: "Test only")
    func openFeedbackMail()

    @available(*, deprecated, message: "Test only")
    func openAppStoreReview()
}
