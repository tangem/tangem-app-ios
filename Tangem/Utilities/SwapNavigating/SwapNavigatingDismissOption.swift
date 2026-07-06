//
//  SwapNavigatingDismissOption.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// Payload for reopening the regular Swap flow after the Send flow is dismissed.
/// Carries only value types; wallet models are re-resolved at dismiss time,
/// mirroring `FeeCurrencyNavigatingDismissOption`.
struct SwapNavigatingDismissOption {
    let userWalletId: UserWalletId
    let sourceTokenItem: TokenItem
    let receiveTokenItem: TokenItem

    /// Returns `nil` when the source wallet model can't be found (e.g. the wallet was removed mid-flow).
    func makeSwapFlowOptions(source: SendCoordinator.Source) -> SendCoordinator.Options? {
        guard let sourceResult = try? WalletModelFinder.findWalletModel(userWalletId: userWalletId, tokenItem: sourceTokenItem) else {
            AppLogger.error(error: "Source wallet model not found for the manual swap redirect")
            return nil
        }

        let sourceToken = CommonSendSwapableTokenFactory(
            userWalletInfo: sourceResult.userWalletModel.userWalletInfo,
            walletModel: sourceResult.walletModel,
            operationType: .swap
        ).makeSwapableToken()

        // The receive side must be wallet-model-backed: the regular swap flow has no
        // destination step and requires a real address (SwapModel.mapToReadyToTransferState).
        let receiveToken = (try? WalletModelFinder.findWalletModel(userWalletId: userWalletId, tokenItem: receiveTokenItem))
            .map { result in
                CommonSendSwapableTokenFactory(
                    userWalletInfo: result.userWalletModel.userWalletInfo,
                    walletModel: result.walletModel,
                    operationType: .swap
                ).makeSwapableToken()
            }

        return SendCoordinator.Options(type: .swap(.from(sourceToken, receive: receiveToken)), source: source)
    }
}
