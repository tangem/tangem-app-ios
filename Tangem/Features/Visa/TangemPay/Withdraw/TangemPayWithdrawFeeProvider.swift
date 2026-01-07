//
//  TangemPayWithdrawFeeProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress

/// Basically the `TangemPay` don't have the crypto fee on the user side
/// But `Express module` required `ExpressFeeProvider` for the `source` token
struct TangemPayWithdrawExpressFeeProvider {
    let feeTokenItem: TokenItem

    private var constantFee: BSDKFee {
        BSDKFee(BSDKAmount(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: 0))
    }

    private var constantTokenFee: TokenFee {
        .init(option: .market, tokenItem: feeTokenItem, value: .success(constantFee))
    }

    init(feeTokenItem: TokenItem) {
        self.feeTokenItem = feeTokenItem
    }
}

// MARK: - ExpressFeeProvider

extension TangemPayWithdrawExpressFeeProvider: ExpressFeeProvider {
    func estimatedFee(amount: Decimal, option: ExpressFee.Option) async throws -> Fee {
        constantFee
    }

    func estimatedFee(estimatedGasLimit: Int, option: ExpressFee.Option) async throws -> Fee {
        constantFee
    }

    func getFee(amount: ExpressAmount, destination: String, option: ExpressFee.Option) async throws -> Fee {
        constantFee
    }
}

// MARK: - TokenFeeProvider

extension TangemPayWithdrawExpressFeeProvider: TokenFeeProvider {
    var fees: [TokenFee] { [constantTokenFee] }

    var feesPublisher: AnyPublisher<[TokenFee], Never> {
        .just(output: fees)
    }
}
