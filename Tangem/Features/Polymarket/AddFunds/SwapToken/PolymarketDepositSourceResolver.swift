//
//  PolymarketDepositSourceResolver.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemExpress

final class PolymarketDepositSourceResolver {
    private let userWalletInfo: UserWalletInfo
    private let walletModelsProvider: MainScreenUIOrderedWalletModelsProvider
    private let availabilityChecker: FundingSourceAvailabilityChecker
    private let depositCurrencies: Set<ExpressWalletCurrency>

    init(
        userWalletInfo: UserWalletInfo,
        walletModelsProvider: MainScreenUIOrderedWalletModelsProvider,
        depositCurrencies: Set<ExpressWalletCurrency>,
        availabilityChecker: FundingSourceAvailabilityChecker
    ) {
        self.userWalletInfo = userWalletInfo
        self.walletModelsProvider = walletModelsProvider
        self.depositCurrencies = depositCurrencies
        self.availabilityChecker = availabilityChecker
    }
}

// MARK: - SwapSourceTokenResolver

extension PolymarketDepositSourceResolver: SwapSourceTokenResolver {
    var initialSource: LoadingResult<SendSwapableToken, any Error> { .loading }

    func resolveSource(for receive: SendReceiveToken?) async throws -> SendSwapableToken {
        let walletModels = await walletModelsProvider.settledWalletModels()

        guard let source = resolveSourceToken(from: walletModels) else {
            throw SwapModel.SwapModelError.tokenSelectionRequired
        }

        return source
    }
}

// MARK: - Choosing the source

extension PolymarketDepositSourceResolver {
    static func chooseSource(
        from walletModels: [any WalletModel],
        depositCurrencies: Set<ExpressWalletCurrency>,
        availabilityChecker: FundingSourceAvailabilityChecker
    ) -> (any WalletModel)? {
        let selectable = walletModels.filter { !$0.isJointAccountParticipant }

        let matching = selectable.filter {
            depositCurrencies.contains($0.tokenItem.expressCurrency)
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
            depositCurrencies: depositCurrencies,
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
