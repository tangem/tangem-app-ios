//
//  DemoTokenFeeProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct DemoTokenFeeProvider {
    let tokenItem: TokenItem
}

// MARK: - TokenFeeProvider

extension DemoTokenFeeProvider: TokenFeeProvider {
    func estimatedFee(amount: Decimal) async throws -> [BSDKFee] {
        let fees = DemoUtil().getDemoFee(for: tokenItem.blockchain)
        return fees
    }

    func getFee(dataType: TokenFeeProviderDataType) async throws -> [BSDKFee] {
        let fees = DemoUtil().getDemoFee(for: tokenItem.blockchain)
        return fees
    }
}
