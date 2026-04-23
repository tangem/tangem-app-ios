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
        let tokenSelectorViewModel = TokenSelectorViewModel.common(
            availabilityProvider: .swap(),
            initialSelectedItem: direction.tokenItem
        )

        return SwapTokenSelectorViewModel(
            swapDirection: direction,
            tokenSelectorViewModel: tokenSelectorViewModel,
            marketsTokensViewModel: marketsTokensViewModel,
            output: output,
            tokenSelectorCoordinator: router,
            marketsTokenAdditionCoordinator: marketsTokenAdditionRouter
        )
    }
}
