//
//  CommonMainCoordinatorChildFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

final class CommonMainCoordinatorChildFactory {}

extension CommonMainCoordinatorChildFactory: MainCoordinatorChildFactory {
    func makeTokenDetailsCoordinator(dismissAction: @escaping Action<Void>) -> TokenDetailsCoordinator {
        TokenDetailsCoordinator(dismissAction: dismissAction)
    }

    func makeBuyCoordinator(dismissAction: @escaping Action<Void>) -> ActionButtonsBuyCoordinator {
        ActionButtonsBuyCoordinator(dismissAction: dismissAction)
    }

    func makeSwapCoordinator(
        userWalletModel: UserWalletModel,
        dismissAction: @escaping ExpressCoordinator.DismissAction,
    ) -> ActionButtonsSwapCoordinator {
        ActionButtonsSwapCoordinator(
            expressTokensListAdapter: CommonExpressTokensListAdapter(userWalletId: userWalletModel.userWalletId),
            userWalletModel: userWalletModel,
            dismissAction: dismissAction,
            tokenSorter: SwapSourceTokenAvailabilitySorter(userWalletModelConfig: userWalletModel.config),
            yieldModuleNotificationInteractor: YieldModuleNoticeInteractor()
        )
    }

    func makeSellCoordinator(
        userWalletModel: UserWalletModel,
        dismissAction: @escaping Action<ActionButtonsSendToSellModel?>
    ) -> ActionButtonsSellCoordinator {
        ActionButtonsSellCoordinator(
            expressTokensListAdapter: CommonExpressTokensListAdapter(userWalletId: userWalletModel.userWalletId),
            dismissAction: dismissAction,
            userWalletModel: userWalletModel
        )
    }

    func makeReferralCoordinator(dismissAction: @escaping Action<Void>) -> ReferralCoordinator {
        ReferralCoordinator(dismissAction: dismissAction)
    }

    func makeStakingCoordinator(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) -> StakingDetailsCoordinator {
        StakingDetailsCoordinator(dismissAction: dismissAction, popToRootAction: popToRootAction)
    }

    func makeMarketsTokenDetailsCoordinator() -> MarketsTokenDetailsCoordinator {
        let coordinator = MarketsTokenDetailsCoordinator()
        return coordinator
    }

    func makeTangemPayOnboardingCoordinator(
        dismissAction: @escaping Action<TangemPayOnboardingCoordinator.DismissOptions?>
    ) -> TangemPayOnboardingCoordinator {
        let coordinator = TangemPayOnboardingCoordinator(dismissAction: dismissAction)
        return coordinator
    }
}
