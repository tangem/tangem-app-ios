//
//  PolymarketAccountTokenFeeProvidersManagerProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct PolymarketAccountTokenFeeLoader: TokenFeeLoader {
    let feeTokenItem: TokenItem

    private var zeroFee: BSDKFee {
        BSDKFee(BSDKAmount(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: 0))
    }

    func estimatedFee(amount: Decimal) async throws -> [BSDKFee] {
        [zeroFee]
    }

    func getFee(amount: Decimal, destination: String) async throws -> [BSDKFee] {
        [zeroFee]
    }
}

struct PolymarketAccountTokenFeeProvidersManagerProvider {
    let feeTokenItem: TokenItem
    let feeTokenItemBalanceProvider: any TokenBalanceProvider
}

// MARK: - TokenFeeProvidersManagerProvider

extension PolymarketAccountTokenFeeProvidersManagerProvider: TokenFeeProvidersManagerProvider {
    func makeTokenFeeProvidersManager() -> TokenFeeProvidersManager {
        let feeProvider: TokenFeeProvider = CommonTokenFeeProvider(
            feeTokenItem: feeTokenItem,
            tokenFeeLoader: PolymarketAccountTokenFeeLoader(feeTokenItem: feeTokenItem),
            customFeeProvider: .none,
            feeTokenItemBalanceProvider: feeTokenItemBalanceProvider,
            supportingOptions: .all
        )

        return CommonTokenFeeProvidersManager(
            feeProviders: [feeProvider],
            initialSelectedProvider: feeProvider,
            ownerAddress: nil
        )
    }
}
