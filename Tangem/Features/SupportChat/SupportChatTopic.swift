//
//  SupportChatTopic.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum SupportChatTopic {
    case swap
    case polymarket
    case socialLogin

    var usedeskFieldValue: String {
        switch self {
        case .swap: "swap"
        case .polymarket: "polymarket"
        case .socialLogin: "social_login"
        }
    }

    static let usedeskFieldId = 245
}
