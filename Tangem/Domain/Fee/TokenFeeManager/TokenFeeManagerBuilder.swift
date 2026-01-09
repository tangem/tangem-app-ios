//
//  TokenFeeManagerBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct TokenFeeManagerBuilder {
    func makeTokenFeeManager(walletModel: any WalletModel) -> TokenFeeManager {
        var feeProviders = [walletModel.tokenFeeProvider] // Main

        // [REDACTED_TODO_COMMENT]

        return TokenFeeManager(feeProviders: feeProviders, initialSelectedProvider: walletModel.tokenFeeProvider)
    }
}
