//
//  NotificationSettingsFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct NotificationSettingsFactory {
    func buildMissingDerivationNotificationSettings(for numberOfNetworks: Int) -> NotificationView.Settings {
        .init(
            colorScheme: .white,
            icon: .init(image: Assets.blueCircleWarning.image),
            title: Localization.mainWarningMissingDerivationTitle,
            description: Localization.mainWarningMissingDerivationDescription(numberOfNetworks),
            isDismissable: false,
            dismissAction: nil
        )
    }
}
