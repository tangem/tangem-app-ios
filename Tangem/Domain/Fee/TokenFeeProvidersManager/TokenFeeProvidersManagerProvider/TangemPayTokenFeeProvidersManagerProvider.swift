//
//  TangemPayTokenFeeProvidersManagerProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct TangemPayTokenFeeProvidersManagerProvider {
    let feeTokenItem: TokenItem
    let feeTokenItemBalanceProvider: any TokenBalanceProvider
}

// MARK: - TokenFeeProvidersManagerProvider

extension TangemPayTokenFeeProvidersManagerProvider: TokenFeeProvidersManagerProvider {
    func makeTokenFeeProvidersManager() -> TokenFeeProvidersManager {
        let tokenFeeLoader = TangemPayTokenFeeLoader(feeTokenItem: feeTokenItem)
        let feeProvider: TokenFeeProvider = CommonTokenFeeProvider(
            feeTokenItem: feeTokenItem,
            tokenFeeLoader: tokenFeeLoader,
            customFeeProvider: .none,
            feeTokenItemBalanceProvider: feeTokenItemBalanceProvider,
            supportingOptions: .all,
        )

        return CommonTokenFeeProvidersManager(
            feeProviders: [feeProvider],
            initialSelectedProvider: feeProvider
        )
    }
}
