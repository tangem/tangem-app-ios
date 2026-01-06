//
//  TokenFeeConverter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation

enum SendFeeConverter {
    static func mapToTokenFees(fees: [BSDKFee], feeTokenItem: TokenItem) -> [SendFee] {
        switch fees.count {
        case 1:
            return [
                SendFee(option: .market, tokenItem: feeTokenItem, value: .success(fees[0])),
            ]
        // Express estimated fee case
        case 2:
            return [
                SendFee(option: .market, tokenItem: feeTokenItem, value: .success(fees[0])),
                SendFee(option: .fast, tokenItem: feeTokenItem, value: .success(fees[1])),
            ]
        case 3:
            return [
                SendFee(option: .slow, tokenItem: feeTokenItem, value: .success(fees[0])),
                SendFee(option: .market, tokenItem: feeTokenItem, value: .success(fees[1])),
                SendFee(option: .fast, tokenItem: feeTokenItem, value: .success(fees[2])),
            ]
        default:
            assertionFailure("Wrong count of fees")
            return []
        }
    }
}
