//
//  CommonMainCoordinatorChildFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

final class CommonMainCoordinatorChildFactory: MainCoordinatorChildFactory {
    func makeTokenDetailsCoordinator(dismissAction: @escaping Action<Void>) -> TokenDetailsCoordinator {
        TokenDetailsCoordinator(dismissAction: dismissAction)
    }

    func makeBuyCoordinator(dismissAction: @escaping Action<ActionButtonsBuyDismissPayload?>) -> ActionButtonsBuyCoordinator {
        ActionButtonsBuyCoordinator(dismissAction: dismissAction)
    }

    func makeSellCoordinator(
        userWalletModel: UserWalletModel,
        dismissAction: @escaping Action<ActionButtonsSendToSellModel?>
    ) -> ActionButtonsSellCoordinator {
        ActionButtonsSellCoordinator(
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

    func makeMarketsSearchCoordinator(dismissAction: @escaping Action<Void>) -> MarketsSearchCoordinator {
        MarketsSearchCoordinator(dismissAction: dismissAction)
    }

    func makeEarnCoordinator(dismissAction: @escaping Action<Void>) -> EarnCoordinator {
        EarnCoordinator(
            dismissAction: dismissAction,
            routeOnEarnTokenResolvedAction: { _, _ in }
        )
    }

    func makeTangemPayOnboardingCoordinator(
        dismissAction: @escaping Action<TangemPayOnboardingCoordinator.DismissOptions?>
    ) -> TangemPayOnboardingCoordinator {
        let coordinator = TangemPayOnboardingCoordinator(dismissAction: dismissAction)
        return coordinator
    }
}
