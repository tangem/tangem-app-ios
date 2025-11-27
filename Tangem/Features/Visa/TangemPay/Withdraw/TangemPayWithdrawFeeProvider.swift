//
//  TangemPayWithdrawFeeProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemExpress

// Add implementation
// [REDACTED_TODO_COMMENT]
struct TangemPayWithdrawExpressFeeProvider {}

// MARK: - ExpressFeeProvider

extension TangemPayWithdrawExpressFeeProvider: ExpressFeeProvider {
    func estimatedFee(amount: Decimal) async throws -> ExpressFee.Variants {
        throw CommonError.notImplemented
    }

    func estimatedFee(estimatedGasLimit: Int) async throws -> Fee {
        throw CommonError.notImplemented
    }

    func getFee(amount: ExpressAmount, destination: String) async throws -> ExpressFee.Variants {
        throw CommonError.notImplemented
    }
}
