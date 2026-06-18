//
//  Analytics+SupportChatSource.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension Analytics {
    enum SupportChatSource {
        case settings
        case swap

        var parameterValue: Analytics.ParameterValue {
            switch self {
            case .settings: .settings
            case .swap: .swap
            }
        }
    }
}
