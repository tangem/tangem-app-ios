//
//  DemoTokenFeeProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct DemoTokenFeeProvider {
    let feeTokenItem: TokenItem
}

// MARK: - TokenFeeProvider

extension DemoTokenFeeProvider: TokenFeeProvider {
    func estimatedFee(amount: Decimal) async throws -> [TokenFee] {
        let fees = DemoUtil().getDemoFee(for: feeTokenItem.blockchain)
        return SendFeeConverter.mapToTokenFees(fees: fees, feeTokenItem: feeTokenItem)
    }

    func getFee(dataType: TokenFeeProviderDataType) async throws -> [TokenFee] {
        let fees = DemoUtil().getDemoFee(for: feeTokenItem.blockchain)
        return SendFeeConverter.mapToTokenFees(fees: fees, feeTokenItem: feeTokenItem)
    }
}
