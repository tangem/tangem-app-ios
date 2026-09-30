//
//  SupportChatSource.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum SupportChatSource {
    case settings
    case swap
    case deeplink
    case polymarket

    var analyticsParameterValue: Analytics.ParameterValue {
        switch self {
        case .settings: .settings
        case .swap: .swap
        case .deeplink: .deeplink
        case .polymarket: .predictions
        }
    }

    var topic: SupportChatTopic? {
        switch self {
        case .swap: .swap
        case .polymarket: .polymarket
        case .settings, .deeplink: nil
        }
    }
}
