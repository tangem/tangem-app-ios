//
//  TangemPayTokenFeeLoader.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Basically the `TangemPay` don't have the crypto fee on the user side
/// But we have to have some loader to close requirements
struct TangemPayTokenFeeLoader {
    let feeTokenItem: TokenItem

    private var constantFee: BSDKFee {
        BSDKFee(BSDKAmount(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: 0))
    }

    init(feeTokenItem: TokenItem) {
        self.feeTokenItem = feeTokenItem
    }
}

extension TangemPayTokenFeeLoader: TokenFeeLoader {
    var allowsFeeSelection: Bool { false }

    func estimatedFee(amount: Decimal) async throws -> [BSDKFee] { [constantFee] }
    func getFee(amount: Decimal, destination: String) async throws -> [BSDKFee] { [constantFee] }
}
