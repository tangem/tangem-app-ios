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
    var isDismissable: Bool { get }
    var analyticsEvent: Analytics.Event? { get }
    var analyticsParams: [Analytics.ParameterKey: String] { get }
}
