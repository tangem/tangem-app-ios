//
//  PolymarketWithdrawDestinationResolver.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket

struct PolymarketWithdrawDestinationResolver {
    let userWalletInfo: UserWalletInfo
    let walletModelsProvider: MainScreenUIOrderedWalletModelsProvider

    func resolve() async -> SendReceiveToken? {
        let walletModels = (try? await walletModelsProvider.walletModelsPublisher.async()) ?? []

        guard let walletModel = Self.chooseDestination(from: walletModels, userWalletInfo: userWalletInfo) else {
            return nil
        }

        return WalletModelSendTokenFactory(
            userWalletInfo: userWalletInfo,
            walletModel: walletModel,
            operationType: .swap
        )
        .makeReceiveToken()
    }
}

// MARK: - Choosing the destination

extension PolymarketWithdrawDestinationResolver {
    static func chooseDestination(from walletModels: [any WalletModel], userWalletInfo: UserWalletInfo) -> (any WalletModel)? {
        let currency = PolymarketUtilities.usdcTokenItem.expressCurrency

        return walletModels.first { walletModel in
            guard walletModel.tokenItem.expressCurrency == currency else {
                return false
            }

            let availability = TokenActionAvailabilityProvider(userWalletInfo: userWalletInfo, walletModel: walletModel).swapReceiveAvailability()
            return SwapReceivePreselectionEligibility.canBecomeReceive(for: availability)
        }
    }
}
