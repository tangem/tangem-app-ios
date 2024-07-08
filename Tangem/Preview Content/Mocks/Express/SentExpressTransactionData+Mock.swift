//
//  SentExpressTransactionData+Mock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

extension SentExpressTransactionData {
    static let mock = SentExpressTransactionData(
        hash: UUID().uuidString,
        source: .mockETH,
        destination: .mockETH,
        fee: 0.032,
        feeOption: .market,
        provider: ExpressProvider(id: "1inch", name: "1inch", type: .dex, imageURL: nil, termsOfUse: nil, privacyPolicy: nil, recommended: nil),
        date: Date(),
        expressTransactionData: .init(
            requestId: "",
            fromAmount: 123,
            toAmount: 32,
            expressTransactionId: "",
            transactionType: .swap,
            sourceAddress: nil,
            destinationAddress: "",
            extraDestinationId: nil,
            value: 123,
            txData: nil,
            otherNativeFee: nil,
            estimatedGasLimit: nil,
            externalTxId: nil,
            externalTxUrl: nil
        )
    )
}
