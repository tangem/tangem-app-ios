//
//  NotificationSettingsRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol NotificationSettingsRoutable: AnyObject, TransactionNotificationsRowToggleRoutable {
    func openAppSettings()
    func onAlertDismiss()
    func dismiss()
}
