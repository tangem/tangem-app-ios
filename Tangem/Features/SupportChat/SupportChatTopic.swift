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

    var usedeskFieldValue: String {
        switch self {
        case .swap: "swap"
        case .polymarket: "polymarket"
        }
    }

    static let usedeskFieldId = 245
}
