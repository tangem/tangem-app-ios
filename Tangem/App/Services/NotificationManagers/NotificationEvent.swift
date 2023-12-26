//
//  NotificationEvent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol NotificationEvent: Hashable {
    var title: String { get }
    var description: String? { get }
    var colorScheme: NotificationView.ColorScheme { get }
    var icon: NotificationView.MessageIcon { get }
    var severity: NotificationView.Severity { get }
    var isDismissable: Bool { get }
    // [REDACTED_TODO_COMMENT]
    var analyticsEvent: Analytics.Event? { get }
    var analyticsParams: [Analytics.ParameterKey: String] { get }
    /// Determine if analytics event should be sent only once and tracked by service
    var isOneShotAnalyticsEvent: Bool { get }
}
