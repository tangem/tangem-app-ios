//
//  TokenFeeProviderBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum TokenFeeProviderBuilder {
    static func makeTokenFeeProvider(walletModel: any WalletModel) -> any TokenFeeProvider {
        CommonTokenFeeProvider(
            feeTokenItem: walletModel.feeTokenItem,
            tokenFeeLoader: walletModel.tokenFeeLoader,
            customFeeProvider: walletModel.customFeeProvider
        )
    }
}
