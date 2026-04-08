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

    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository

    weak var output: SwapTokenSelectorOutput?

    func makeSwapTokenSelectorViewModel(
        direction: SwapTokenSelectorViewModel.SwapDirection,
        router: SwapTokenSelectorRoutable,
        marketsTokensViewModel: SwapMarketsTokensViewModel?,
        marketsTokenAdditionRouter: SwapMarketsTokenAdditionRoutable
    ) -> SwapTokenSelectorViewModel {
        let tokenSelectorViewModel = TokenSelectorViewModel(
            walletsProvider: .common(),
            availabilityProvider: .swap(),
            collapsibleAccounts: true,
            expandedStateStorage: expandedStateStorage,
            initialSelectedItem: direction.tokenItem
        )

        tokenSelectorViewModel.setupWalletFilter(
            currentWalletId: userWalletRepository.selectedModel?.userWalletId
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
