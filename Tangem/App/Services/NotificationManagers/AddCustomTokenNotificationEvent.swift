//
//  AddCustomTokenNotificationEvent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum AddCustomTokenNotificationEvent: Hashable {
    case scamWarning
}

extension AddCustomTokenNotificationEvent: NotificationEvent {
    var title: String {
        switch self {
        case .scamWarning:
            return Localization.customTokenValidationErrorNotFoundTitle
        }
    }

    var description: String? {
        switch self {
        case .scamWarning:
            return Localization.customTokenValidationErrorNotFoundDescription
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        switch self {
        case .scamWarning:
            return .secondary
        }
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .scamWarning:
            return .init(image: Assets.attention.image)
        }
    }

    var isDismissable: Bool {
        switch self {
        case .scamWarning:
            return false
        }
    }
}
