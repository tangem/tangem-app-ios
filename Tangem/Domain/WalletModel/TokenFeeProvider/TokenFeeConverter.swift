//
//  TokenFeeConverter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation

enum SendFeeConverter {
    static func mapToLoadingSendFees(options: [FeeOption], feeTokenItem: TokenItem) -> [SendFee] {
        options.map { option in
            SendFee(option: option, tokenItem: feeTokenItem, value: .loading)
        }
    }

    static func mapToFailureSendFees(options: [FeeOption], feeTokenItem: TokenItem, error: any Error) -> [SendFee] {
        options.map { option in
            SendFee(option: option, tokenItem: feeTokenItem, value: .failure(error))
        }
    }

    static func mapToSendFees(options: [FeeOption], feeTokenItem: TokenItem, fees: [BSDKFee]) -> [SendFee] {
        mapToSendFees(fees: fees, feeTokenItem: feeTokenItem).filter { options.contains($0.option) }
    }

    static func mapToSendFees(fees: [BSDKFee], feeTokenItem: TokenItem) -> [SendFee] {
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
