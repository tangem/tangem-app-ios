//
//  TokenFeeManagerBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct TokenFeeManagerBuilder {
    let walletModel: any WalletModel

    func makeTokenFeeManager() -> TokenFeeManager {
        var feeProviders = [walletModel.tokenFeeProvider] // Main

        // [REDACTED_TODO_COMMENT]

        return TokenFeeManager(feeProviders: feeProviders, initialSelectedProvider: walletModel.tokenFeeProvider)
    }
}
