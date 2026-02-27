//
//  SwapTokenSelectorViewModelBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct SwapTokenSelectorViewModelBuilder {
    weak var output: SwapTokenSelectorOutput?

    func makeSwapTokenSelectorViewModel(
        direction: SwapTokenSelectorViewModel.SwapDirection,
        router: SwapTokenSelectorRoutable,
        marketsTokensViewModel: SwapMarketsTokensViewModel?,
        marketsTokenAdditionRouter: SwapMarketsTokenAdditionRoutable
    ) -> SwapTokenSelectorViewModel {
        SwapTokenSelectorViewModel(
            swapDirection: direction,
            tokenSelectorViewModel: AccountsAwareTokenSelectorViewModel(
                walletsProvider: .common(),
                availabilityProvider: AccountsAwareTokenSelectorItemSwapAvailabilityProvider(showsTangemPayItems: false)
            ),
            marketsTokensViewModel: marketsTokensViewModel,
            output: output,
            tokenSelectorCoordinator: router,
            marketsTokenAdditionCoordinator: marketsTokenAdditionRouter
        )
    }
}
