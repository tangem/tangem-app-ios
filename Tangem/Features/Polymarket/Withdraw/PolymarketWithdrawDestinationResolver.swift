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

        guard let walletModel = Self.chooseDestination(from: walletModels) else {
            return nil
        }

        return CommonSendSwapableTokenFactory(
            userWalletInfo: userWalletInfo,
            walletModel: walletModel,
            operationType: .swap
        )
        .makeSwapableToken()
    }
}

// MARK: - Choosing the destination

extension PolymarketWithdrawDestinationResolver {
    static func chooseDestination(from walletModels: [any WalletModel]) -> (any WalletModel)? {
        let currency = PolymarketUtilities.usdcTokenItem.expressCurrency

        return walletModels.first { walletModel in
            walletModel.tokenItem.expressCurrency == currency && !walletModel.isJointAccountParticipant
        }
    }
}
