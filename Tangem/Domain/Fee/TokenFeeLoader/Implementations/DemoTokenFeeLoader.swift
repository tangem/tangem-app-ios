//
//  DemoTokenFeeLoader.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct DemoTokenFeeLoader {
    let tokenItem: TokenItem
}

// MARK: - TokenFeeLoader

extension DemoTokenFeeLoader: TokenFeeLoader {
    var allowsFeeSelection: Bool { true }

    func estimatedFee(amount: Decimal) async throws -> [BSDKFee] {
        let fees = DemoUtil().getDemoFee(for: tokenItem.blockchain)
        return fees
    }

    func getFee(amount: Decimal, destination: String) async throws -> [BSDKFee] {
        let fees = DemoUtil().getDemoFee(for: tokenItem.blockchain)
        return fees
    }
}
