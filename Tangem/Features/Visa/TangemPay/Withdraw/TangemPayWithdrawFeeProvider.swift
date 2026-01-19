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

    private var constantFee: BSDKFee {
        BSDKFee(BSDKAmount(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: 0))
    }

    init(feeTokenItem: TokenItem) {
        self.feeTokenItem = feeTokenItem
    }
}

// MARK: - ExpressFeeProvider

extension TangemPayWithdrawExpressFeeProvider: ExpressFeeProvider {
    func estimatedFee(request: FeeRequest, amount: Decimal) async throws -> BSDKFee { constantFee }
    func estimatedFee(request: FeeRequest, estimatedGasLimit: Int, otherNativeFee: Decimal?) async throws -> BSDKFee { constantFee }
    func transactionFee(request: FeeRequest, data: ExpressTransactionDataType) async throws -> BSDKFee { constantFee }
}
