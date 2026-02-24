//
//  TangemPayTokenFeeProvidersManagerProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct TangemPayTokenFeeProvidersManagerProvider {
    let feeTokenItem: TokenItem
    let availableTokenBalanceProvider: any TokenBalanceProvider
}

// MARK: - TokenFeeProvidersManagerProvider

extension TangemPayTokenFeeProvidersManagerProvider: TokenFeeProvidersManagerProvider {
    func makeTokenFeeProvidersManager() -> TokenFeeProvidersManager {
        let tokenFeeLoader = TangemPayTokenFeeLoader(feeTokenItem: feeTokenItem)
        let feeProvider: TokenFeeProvider = .common(
            feeTokenItem: feeTokenItem,
            supportingOptions: .all,
            availableTokenBalanceProvider: availableTokenBalanceProvider,
            tokenFeeLoader: tokenFeeLoader,
            customFeeProvider: .none
        )

        return CommonTokenFeeProvidersManager(
            feeProviders: [feeProvider],
            initialSelectedProvider: feeProvider
        )
    }
}
