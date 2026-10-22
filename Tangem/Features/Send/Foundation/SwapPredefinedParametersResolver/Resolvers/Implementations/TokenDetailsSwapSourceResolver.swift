//
//  TokenDetailsSwapSourceResolver.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

// MARK: - Token Details Resolver

final class TokenDetailsSwapSourceResolver {
    @Injected(\.expressAvailabilityProvider) private var expressAvailabilityProvider: ExpressAvailabilityProvider

    private let userWalletInfo: UserWalletInfo

    init(userWalletInfo: UserWalletInfo) {
        self.userWalletInfo = userWalletInfo
    }

    func resolveSource(for destination: any WalletModel) -> (any WalletModel)? {
        let isExchangeable = expressAvailabilityProvider.canSwap(tokenItem: destination.tokenItem)
        let groups = groupAccountTokens(for: destination)

        if isExchangeable {
            if let topExchangeable = groups.topExchangeable {
                return topExchangeable
            }

            if groups.hasExchangeableEmpty {
                return nil
            }
        }

        return groups.mostFunded ?? groups.firstInAccount
    }
}

// MARK: - Private

private extension TokenDetailsSwapSourceResolver {
    func groupAccountTokens(for walletModel: any WalletModel) -> AccountTokenGroups {
        let allModels = walletModel.account?.walletModelsManager.walletModels ?? []

        var groups = AccountTokenGroups()
        var mostFundedFiat: Decimal = 0
        var topExchangeableFiat: Decimal = 0

        for model in allModels {
            guard model.id != walletModel.id else { continue }
            guard TokenActionAvailabilityProvider(userWalletInfo: userWalletInfo, walletModel: model).isSwapAvailable(direction: .from) else { continue }

            if groups.firstInAccount == nil {
                groups.firstInAccount = model
            }

            let isExchangeable = expressAvailabilityProvider.canSwap(tokenItem: model.tokenItem)
            let fiat = model.fiatAvailableBalance
            let hasBalance = fiat > 0

            if hasBalance, fiat > mostFundedFiat {
                mostFundedFiat = fiat
                groups.mostFunded = model
            }

            switch (isExchangeable, hasBalance) {
            case (true, true):
                if fiat > topExchangeableFiat {
                    topExchangeableFiat = fiat
                    groups.topExchangeable = model
                }
            case (true, false):
                groups.hasExchangeableEmpty = true
            default:
                break
            }
        }

        return groups
    }

    struct AccountTokenGroups {
        var topExchangeable: (any WalletModel)?
        var hasExchangeableEmpty: Bool = false
        var mostFunded: (any WalletModel)?
        var firstInAccount: (any WalletModel)?
    }
}
