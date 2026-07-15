//
//  AlertBuilder+PushNotifications.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import struct TangemUIUtils.AlertBinder

extension AlertBuilder {
    /// Shared "enable push notifications" alert (Cancel / Open Settings), reused by the notification
    /// settings screens and the price-alert bell. Callers supply only their own button actions.
    static func makeEnablePushSettingsAlert(
        onCancel: (() -> Void)? = nil,
        onOpenSettings: @escaping () -> Void
    ) -> AlertBinder {
        makeAlert(
            title: Localization.pushNotificationsPermissionAlertTitle,
            message: Localization.pushNotificationsPermissionAlertDescription,
            with: Buttons(
                primaryButton: .cancel(Text(Localization.pushNotificationsPermissionAlertNegativeButton)) {
                    onCancel?()
                },
                secondaryButton: .default(Text(Localization.pushNotificationsPermissionAlertPositiveButton)) {
                    onOpenSettings()
                }
            )
        )
    }
}
