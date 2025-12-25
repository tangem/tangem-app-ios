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
        result: .init(hash: UUID().uuidString, url: URL(string: "https://google.com"), signerType: "card", currentHost: ""),
        source: ExpressInteractorWalletModelWrapper(
            userWalletInfo: UserWalletModelMock().userWalletInfo,
            walletModel: CommonWalletModel.mockETH,
            expressOperationType: .swap
        ),
        destination: ExpressInteractorWalletModelWrapper(
            userWalletInfo: UserWalletModelMock().userWalletInfo,
            walletModel: CommonWalletModel.mockETH,
            expressOperationType: .swap
        ),
        fee: 0.032,
        feeOption: .market,
        provider: ExpressProvider(
            id: "1inch",
            name: "1inch",
            type: .dex,
            exchangeOnlyWithinSingleAddress: false,
            imageURL: nil,
            termsOfUse: nil,
            privacyPolicy: nil,
            recommended: nil,
            slippage: nil
        ),
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
            txValue: 123,
            txData: nil,
            otherNativeFee: nil,
            estimatedGasLimit: nil,
            externalTxId: nil,
            externalTxUrl: nil
        )
    )
}
