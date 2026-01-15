//
//  TokenFeeConverter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation

enum TokenFeeConverter {
    static func mapToLoadingSendFees(options: [FeeOption], feeTokenItem: TokenItem) -> [LoadableTokenFee] {
        options.map { option in
            LoadableTokenFee(option: option, tokenItem: feeTokenItem, value: .loading)
        }
    }

    static func mapToFailureSendFees(options: [FeeOption], feeTokenItem: TokenItem, error: any Error) -> [LoadableTokenFee] {
        options.map { option in
            LoadableTokenFee(option: option, tokenItem: feeTokenItem, value: .failure(error))
        }
    }

    static func mapToSendFees(options: [FeeOption], feeTokenItem: TokenItem, fees: [BSDKFee]) -> [LoadableTokenFee] {
        mapToSendFees(fees: fees, feeTokenItem: feeTokenItem).filter { options.contains($0.option) }
    }

    static func mapToSendFees(fees: [BSDKFee], feeTokenItem: TokenItem) -> [LoadableTokenFee] {
        switch fees.count {
        case 1:
            return [
                LoadableTokenFee(option: .market, tokenItem: feeTokenItem, value: .success(fees[0])),
            ]
        // Express estimated fee case
        case 2:
            return [
                LoadableTokenFee(option: .market, tokenItem: feeTokenItem, value: .success(fees[0])),
                LoadableTokenFee(option: .fast, tokenItem: feeTokenItem, value: .success(fees[1])),
            ]
        case 3:
            return [
                LoadableTokenFee(option: .slow, tokenItem: feeTokenItem, value: .success(fees[0])),
                LoadableTokenFee(option: .market, tokenItem: feeTokenItem, value: .success(fees[1])),
                LoadableTokenFee(option: .fast, tokenItem: feeTokenItem, value: .success(fees[2])),
            ]
        default:
            assertionFailure("Wrong count of fees")
            return []
        }
    }
}
