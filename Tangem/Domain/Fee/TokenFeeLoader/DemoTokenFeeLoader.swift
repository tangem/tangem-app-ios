//
//  DemoTokenFeeLoader.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct DemoTokenFeeLoader {
    let feeTokenItem: TokenItem
}

// MARK: - TokenFeeLoader

extension DemoTokenFeeLoader: TokenFeeLoader {
    func estimatedFee(amount: Decimal) async throws -> [BSDKFee] {
        let fees = DemoUtil().getDemoFee(for: feeTokenItem.blockchain)
        return fees
    }

    func getFee(dataType: TokenFeeLoaderDataType) async throws -> [BSDKFee] {
        let fees = DemoUtil().getDemoFee(for: feeTokenItem.blockchain)
        return fees
    }
}
