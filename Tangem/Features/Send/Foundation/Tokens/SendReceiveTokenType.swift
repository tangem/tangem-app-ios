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
enum SendReceiveTokenType {
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

extension SendReceiveTokenType: Equatable {
    static func == (lhs: SendReceiveTokenType, rhs: SendReceiveTokenType) -> Bool {
        switch (lhs, rhs) {
        case (.same(let lhsToken), .same(let rhsToken)):
            lhsToken.userWalletInfo.id == rhsToken.userWalletInfo.id && lhsToken.tokenItem == rhsToken.tokenItem
        case (.swap(let lhsToken), .swap(let rhsToken)):
            lhsToken.tokenItem == rhsToken.tokenItem
        default: false
        }
    }
}
