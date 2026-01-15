//
//  TokenFeeConverter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation

enum TokenFeeConverter {
    static func mapToLoadingSendFees(options: [FeeOption], feeTokenItem: TokenItem) -> [TokenFee] {
        options.map { option in
            TokenFee(option: option, tokenItem: feeTokenItem, value: .loading)
        }
    }

    static func mapToFailureSendFees(options: [FeeOption], feeTokenItem: TokenItem, error: any Error) -> [TokenFee] {
        options.map { option in
            TokenFee(option: option, tokenItem: feeTokenItem, value: .failure(error))
        }
    }

    static func mapToSendFees(options: [FeeOption], feeTokenItem: TokenItem, fees: [BSDKFee]) -> [TokenFee] {
        mapToSendFees(fees: fees, feeTokenItem: feeTokenItem).filter { options.contains($0.option) }
    }

    static func mapToSendFees(fees: [BSDKFee], feeTokenItem: TokenItem) -> [TokenFee] {
        switch fees.count {
        case 1:
            return [
                TokenFee(option: .market, tokenItem: feeTokenItem, value: .success(fees[0])),
            ]
        // Express estimated fee case
        case 2:
            return [
                TokenFee(option: .market, tokenItem: feeTokenItem, value: .success(fees[0])),
                TokenFee(option: .fast, tokenItem: feeTokenItem, value: .success(fees[1])),
            ]
        case 3:
            return [
                TokenFee(option: .slow, tokenItem: feeTokenItem, value: .success(fees[0])),
                TokenFee(option: .market, tokenItem: feeTokenItem, value: .success(fees[1])),
                TokenFee(option: .fast, tokenItem: feeTokenItem, value: .success(fees[2])),
            ]
        default:
            assertionFailure("Wrong count of fees")
            return []
        }
    }
}
