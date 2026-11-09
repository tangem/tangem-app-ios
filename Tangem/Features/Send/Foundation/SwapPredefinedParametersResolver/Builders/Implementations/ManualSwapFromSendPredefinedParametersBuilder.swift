//
//  ManualSwapFromSendPredefinedParametersBuilder.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct ManualSwapFromSendPredefinedParametersBuilder: SwapPredefinedParametersBuilder {
    let userWalletId: UserWalletId
    let source: WalletModelFinder.Result
    let receiveTokenItem: TokenItem

    func make() -> PredefinedSwapParameters {
        let sourceResolver: any SwapSourceTokenResolver = if canBeSource(result: source), let sourceToken = try? makeSwapableToken(result: source) {
            .resolved(sourceToken)
        } else {
            .userSelection
        }

        // The receive side must be wallet-model-backed: the regular swap flow has no
        // destination step and requires a real address (SwapModel.mapToReadyToTransferState).
        let receiveResult = try? WalletModelFinder.findWalletModel(userWalletId: userWalletId, tokenItem: receiveTokenItem)

        let receive: any SwapReceiveTokenResolver = if let receiveResult, canReceive(result: receiveResult) {
            .resolved(makeReceiveToken(result: receiveResult))
        } else {
            .userSelection
        }

        return PredefinedSwapParameters(
            userWalletInfo: source.userWalletModel.userWalletInfo,
            source: sourceResolver,
            receive: receive
        )
    }
}

// MARK: - Private

private extension ManualSwapFromSendPredefinedParametersBuilder {
    func canBeSource(result: WalletModelFinder.Result) -> Bool {
        SwapSourcePreselectionEligibility.canBecomeSource(for: makeAvailabilityProvider(result: result).swapSourceAvailability())
    }

    func canReceive(result: WalletModelFinder.Result) -> Bool {
        SwapReceivePreselectionEligibility.canBecomeReceive(for: makeAvailabilityProvider(result: result).swapReceiveAvailability())
    }

    func makeAvailabilityProvider(result: WalletModelFinder.Result) -> TokenActionAvailabilityProvider {
        TokenActionAvailabilityProvider(userWalletInfo: result.userWalletModel.userWalletInfo, walletModel: result.walletModel)
    }

    func makeReceiveToken(result: WalletModelFinder.Result) -> SendReceiveToken {
        WalletModelSendTokenFactory(userWalletInfo: result.userWalletModel.userWalletInfo, walletModel: result.walletModel, operationType: .swap).makeReceiveToken()
    }

    func makeSwapableToken(result: WalletModelFinder.Result) throws -> SendSwapableToken {
        try WalletModelSendTokenFactory(userWalletInfo: result.userWalletModel.userWalletInfo, walletModel: result.walletModel, operationType: .swap).makeSwapableToken()
    }
}
