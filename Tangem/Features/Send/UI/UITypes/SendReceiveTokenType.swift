//
//  SendReceiveTokenType.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemMacro

@CaseFlagable
enum SendReceiveTokenType: Equatable {
    case same(SendSourceToken)
    case swap(SendReceiveToken)

    var receiveToken: SendReceiveToken? {
        switch self {
        case .same: nil
        case .swap(let token): token
        }
    }

    var tokenItem: TokenItem {
        switch self {
        case .same(let token): token.tokenItem
        case .swap(let token): token.tokenItem
        }
    }
}
