//
//  MainCoordinatorChildFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

protocol MainCoordinatorChildFactory {
    func makeTokenDetailsCoordinator(dismissAction: @escaping Action<Void>) -> TokenDetailsCoordinator
    func makeBuyCoordinator(dismissAction: @escaping Action<Void>) -> ActionButtonsBuyCoordinator

    func makeSellCoordinator(
        userWalletModel: UserWalletModel,
        dismissAction: @escaping Action<ActionButtonsSendToSellModel?>
    ) -> ActionButtonsSellCoordinator

    func makeSwapCoordinator(
        userWalletModel: UserWalletModel,
        dismissAction: @escaping ExpressCoordinator.DismissAction,
    ) -> ActionButtonsSwapCoordinator

    func makeReferralCoordinator(dismissAction: @escaping Action<Void>) -> ReferralCoordinator

    func makeStakingCoordinator(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) -> StakingDetailsCoordinator

    func makeMarketsTokenDetailsCoordinator() -> MarketsTokenDetailsCoordinator
    func makeTangemPayOnboardingCoordinator(
        dismissAction: @escaping Action<TangemPayOnboardingCoordinator.DismissOptions?>
    ) -> TangemPayOnboardingCoordinator
}
