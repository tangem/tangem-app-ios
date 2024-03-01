//
//  NotificationEvent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol NotificationEvent: Hashable, Identifiable {
    var id: String { get }
    var title: NotificationView.Title { get }
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

extension NotificationEvent {
    // Unique ID. Overwrite if hash value is not enough (may be influenced by associated values)
    var id: String {
        "\(hashValue)"
    }
}
