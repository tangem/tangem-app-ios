//
//  SwapTokenSelectorViewModelBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct SwapTokenSelectorViewModelBuilder {
    @Injected(\.swapTokenSelectorExpandedStateStorage)
    private var expandedStateStorage: SwapTokenSelectorExpandedStateStorage

    weak var output: SwapTokenSelectorOutput?

    func makeSwapTokenSelectorViewModel(
        direction: SwapTokenSelectorViewModel.SwapDirection,
        router: SwapTokenSelectorRoutable,
        marketsTokensViewModel: SwapMarketsTokensViewModel?,
        marketsTokenAdditionRouter: SwapMarketsTokenAdditionRoutable
    ) -> SwapTokenSelectorViewModel {
        SwapTokenSelectorViewModel(
            swapDirection: direction,
            tokenSelectorViewModel: TokenSelectorViewModel(
                walletsProvider: .common(),
                availabilityProvider: .swap(),
                collapsibleAccounts: true,
                expandedStateStorage: expandedStateStorage
            ),
            marketsTokensViewModel: marketsTokensViewModel,
            output: output,
            tokenSelectorCoordinator: router,
            marketsTokenAdditionCoordinator: marketsTokenAdditionRouter
        )
    }
}
