//
//  SingleWalletMainContentViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine

final class SingleWalletMainContentViewModel: SingleTokenViewModel {
    // MARK: - ViewState

    // MARK: - Dependencies

    private unowned let singleWalletCoordinator: SingleWalletMainContentRoutable

    init(
        userWalletModel: UserWalletModel,
        walletModel: WalletModel,
        userTokensManager: UserTokensManager,
        exchangeUtility: ExchangeCryptoUtility,
        coordinator: SingleWalletMainContentRoutable
    ) {
        singleWalletCoordinator = coordinator

        super.init(
            userWalletModel: userWalletModel,
            walletModel: walletModel,
            userTokensManager: userTokensManager,
            exchangeUtility: exchangeUtility,
            coordinator: coordinator
        )
    }
}
