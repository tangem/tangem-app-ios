//
//  PolymarketFundingFlow.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket

struct PolymarketFundingFlow {
    let dependencies: PolymarketMainDependencies

    var isRegionBlocked: Bool {
        dependencies.geoblockStateProvider.state.isBlocked
    }

    func makeAddFundsSheet(
        routable: PolymarketAddFundsSheetRoutable
    ) throws(PolymarketFundingError) -> PolymarketAddFundsSheetViewModel {
        guard let accountModel = dependencies.accountModel else {
            throw .missingPolymarketAccountModel
        }

        return PolymarketAddFundsSheetViewModel(
            interactor: dependencies.accountFundsInteractor,
            swapParametersFactory: dependencies.makeSwapParametersFactory(accountModel: accountModel),
            coordinator: routable
        )
    }

    func makeWithdrawSource() throws(PolymarketFundingError) -> PolymarketWithdrawSource {
        guard let accountModel = dependencies.accountModel else {
            throw .missingPolymarketAccountModel
        }

        guard case .ready(let readiness) = dependencies.accountFundsInteractor.state else {
            throw .missingVerifiedDepositWallet
        }

        guard case .available(let minimumUSD) = readiness.withdrawalAvailability else {
            throw .unknownWithdrawalMinimum
        }

        return dependencies.withdrawContext.makeSource(
            accountModel: accountModel,
            depositWalletAddress: readiness.depositWalletAddress,
            minimumUSD: minimumUSD
        )
    }

    func makeWithdrawParameters(
        from source: PolymarketWithdrawSource
    ) async throws(PolymarketFundingError) -> PredefinedSwapParameters {
        guard let accountModel = dependencies.accountModel else {
            throw .missingPolymarketAccountModel
        }

        let receiveToken = await PolymarketWithdrawDestinationResolver(
            userWalletInfo: dependencies.userWalletModel.userWalletInfo,
            walletModelsProvider: dependencies.walletModelsProvider
        )
        .resolve()

        return dependencies
            .makeSwapParametersFactory(accountModel: accountModel)
            .make(withdrawingFrom: source, receiveToken: receiveToken)
    }

    var currentBalance: Decimal? {
        dependencies.fundsArrivalTracker.currentBalance
    }

    func awaitDeposit(since baseline: Decimal?) {
        let activityService = dependencies.activityService

        dependencies.fundsArrivalTracker.startAwaitingFunds(since: baseline) {
            Task { await activityService.reconcileDeposits() }
        }
    }

    func awaitWithdrawal(since baseline: Decimal?) {
        dependencies.fundsArrivalTracker.startAwaitingBalanceChange(since: baseline)
    }
}

// MARK: - Errors

enum PolymarketFundingError: Error {
    case missingPolymarketAccountModel
    case missingVerifiedDepositWallet
    case unknownWithdrawalMinimum
}
