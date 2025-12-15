//
//  TangemPayWithdrawFeeProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemExpress

/// Basically the `TangemPay` don't have the crypto fee on the user side
/// But `Express module` required `ExpressFeeProvider` for the `source` token
struct TangemPayWithdrawExpressFeeProvider {
    let feeTokenItem: TokenItem

    private var constantFee: Fee {
        Fee(BSDKAmount(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: 0))
    }

    init(feeTokenItem: TokenItem) {
        self.feeTokenItem = feeTokenItem
    }
}

// MARK: - ExpressFeeProvider

extension TangemPayWithdrawExpressFeeProvider: ExpressFeeProvider {
    func estimatedFee(amount: Decimal) async throws -> ExpressFee.Variants {
        .single(constantFee)
    }

    func estimatedFee(estimatedGasLimit: Int) async throws -> Fee {
        constantFee
    }

    func getFee(amount: ExpressAmount, destination: String) async throws -> ExpressFee.Variants {
        .single(constantFee)
    }
}
