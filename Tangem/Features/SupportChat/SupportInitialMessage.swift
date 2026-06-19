//
//  SupportInitialMessage.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum SupportInitialMessage {
    case swap(message: String)
    case custom(message: String)

    var additionalFieldValue: String? {
        switch self {
        case .swap: "swap"
        case .custom: nil
        }
    }

    var message: String {
        switch self {
        case .swap(let message): message
        case .custom(let message): message
        }
    }

    /// Usedesk additional field ID used to mark swap-related chats for support-side routing.
    static let swapAdditionalFieldId = 245
}
