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
        let coinTokenFeeProvider = TokenFeeProviderBuilder.makeTokenFeeProvider(walletModel: walletModel)
        let feeProviders = [coinTokenFeeProvider] // Main

        // Add gasless tokens providers
        // [REDACTED_TODO_COMMENT]

        return TokenFeeManager(feeProviders: feeProviders, initialSelectedProvider: coinTokenFeeProvider)
    }
}
