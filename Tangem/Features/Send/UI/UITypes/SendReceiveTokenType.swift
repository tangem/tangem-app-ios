//
//  SendReceiveTokenType.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum SendReceiveTokenType: Hashable {
    case same(TokenItem)
    case swap(SendReceiveToken)

    var receiveToken: SendReceiveToken? {
        switch self {
        case .same: nil
        case .swap(let token): token
        }
    }

    var tokenItem: TokenItem {
        switch self {
        case .same(let token): token
        case .swap(let token): token.tokenItem
        }
    }
}
