//
//  PolymarketDepositSourceResolver.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

final class PolymarketDepositSourceResolver {
    private let userWalletInfo: UserWalletInfo
    private let walletModelsProvider: MainScreenUIOrderedWalletModelsProvider
    private let availabilityChecker: FundingSourceAvailabilityChecker
    private let depositCurrency: ExpressWalletCurrency

    init(
        userWalletInfo: UserWalletInfo,
        walletModelsProvider: MainScreenUIOrderedWalletModelsProvider,
        depositCurrency: ExpressWalletCurrency,
        availabilityChecker: FundingSourceAvailabilityChecker
    ) {
        self.userWalletInfo = userWalletInfo
        self.walletModelsProvider = walletModelsProvider
        self.depositCurrency = depositCurrency
        self.availabilityChecker = availabilityChecker
    }
}

// MARK: - SwapSourceTokenResolver

extension PolymarketDepositSourceResolver: SwapSourceTokenResolver {
    func resolve() async -> SendSwapableToken? {
        let walletModels = await walletModelsProvider.settledWalletModels()
        return resolveSourceToken(from: walletModels)
    }
}

// MARK: - Choosing the source

extension PolymarketDepositSourceResolver {
    static func chooseSource(
        from walletModels: [any WalletModel],
        depositCurrency: ExpressWalletCurrency,
        availabilityChecker: FundingSourceAvailabilityChecker
    ) -> (any WalletModel)? {
        let selectable = walletModels.filter { !$0.isJointAccountParticipant }

        let matching = selectable.filter {
            $0.tokenItem.expressCurrency == depositCurrency
                && availabilityChecker.isTransferAvailable(walletModel: $0)
        }

        if let matchingSource = matching.mostFiatFundedOrFirst {
            return matchingSource
        }

        let candidates = selectable.filter { availabilityChecker.isSwapAvailable(walletModel: $0) }
        return candidates.mostFiatFundedOrFirst
    }
}

// MARK: - Private implementation

private extension PolymarketDepositSourceResolver {
    func resolveSourceToken(from walletModels: [any WalletModel]) -> SendSwapableToken? {
        let chosen = Self.chooseSource(
            from: walletModels,
            depositCurrency: depositCurrency,
            availabilityChecker: availabilityChecker
        )

        guard let chosen else {
            return nil
        }

        return CommonSendSwapableTokenFactory(
            userWalletInfo: userWalletInfo,
            walletModel: chosen,
            operationType: .swap
        ).makeSwapableToken()
    }
}
