//
//  CommonTokenFeeLoader.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation

struct CommonTokenFeeLoader {
    let tokenItem: TokenItem
    let transactionFeeProvider: any TransactionFeeProvider
}

// MARK: - TokenFeeLoader

extension CommonTokenFeeLoader: TokenFeeLoader {
    func estimatedFee(amount: Decimal) async throws -> [BSDKFee] {
        let amount = makeAmount(amount: amount)
        let fees = try await transactionFeeProvider.estimatedFee(amount: amount).async()
        return fees
    }

    func getFee(amount: Decimal, destination: String) async throws -> [BSDKFee] {
        let amount = makeAmount(amount: amount)
        let fees = try await transactionFeeProvider.getFee(amount: amount, destination: destination).async()
        return fees
    }
}

// MARK: - Private

private extension CommonTokenFeeLoader {
    func makeAmount(amount: Decimal) -> BSDKAmount {
        BSDKAmount(with: tokenItem.blockchain, type: tokenItem.amountType, value: amount)
    }
}
