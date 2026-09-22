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
        dependencies.geoblockStateProvider.state == .blocked
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

        let fundsState = dependencies.accountFundsInteractor.state

        guard let depositWalletAddress = fundsState.depositWalletAddress else {
            throw .missingVerifiedDepositWallet
        }

        return dependencies.withdrawContext.makeSource(
            accountModel: accountModel,
            depositWalletAddress: depositWalletAddress,
            minimumUSD: fundsState.depositTarget?.asset.minCheckoutUSD
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

    func awaitDeposit() {
        dependencies.fundsArrivalTracker.startAwaitingFunds()
    }

    func awaitWithdrawal() {
        dependencies.fundsArrivalTracker.startAwaitingWithdrawal()
    }
}

// MARK: - Errors

enum PolymarketFundingError: Error {
    case missingPolymarketAccountModel
    case missingVerifiedDepositWallet
}
