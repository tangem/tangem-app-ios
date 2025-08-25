//
//  NotificationViewInput.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

typealias NotificationViewId = Int

struct NotificationViewInput: Identifiable, Equatable {
    let style: NotificationView.Style
    let severity: NotificationView.Severity
    let settings: NotificationView.Settings

    var id: NotificationViewId { settings.id }
}
