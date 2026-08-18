//
//  SwapTokenSelectorViewModelBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct SwapTokenSelectorViewModelBuilder {
    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository

    weak var output: (SwapTokenSelectorOutput & SendSourceTokenInput & SendReceiveTokenInput)?
    /// Replaces the default wallets provider for the *source* selector only (account funding
    /// flows restrict what can fund or be withdrawn from the account).
    var sourceWalletsProvider: (any TokenSelectorWalletsProvider)?

    func makeSwapTokenSelectorViewModel(
        direction: SwapTokenSelectorViewModel.SwapDirection,
        router: SwapTokenSelectorRoutable,
        marketsTokensViewModel: SwapMarketsTokensViewModel?,
        marketsTokenAdditionRouter: SwapMarketsTokenAdditionRoutable
    ) -> SwapTokenSelectorViewModel {
        // `SwapDirection` cases name the *fixed* side; the user is replacing the *opposite* one.
        // We want the token currently shown on the tapped (replaced) button — hence the inversion.
        let tappedToken: (any SendSourceToken)?
        switch direction {
        case .toDestination:
            // destination is fixed → user tapped the source button
            tappedToken = output?.sourceToken.value
        case .fromSource:
            // source is fixed → user tapped the receive button
            tappedToken = output?.receiveToken.value as? (any SendSourceToken)
        }

        let initiallyExpandedAccount = tappedToken.flatMap { resolveInitiallyExpandedAccount(for: $0) }

        let preferredWalletId = tappedToken?.userWalletInfo.id
            ?? userWalletRepository.selectedModel?.userWalletId

        // `.toDestination` = the user is picking the source token.
        let isSourceSelection = if case .toDestination = direction { true } else { false }
        let restrictedWalletsProvider = isSourceSelection ? sourceWalletsProvider : nil
        let showsBalanceFilter = isSourceSelection && FeatureProvider.isAvailable(.swapHideZeroBalanceSource)

        let tokenSelectorViewModel = TokenSelectorViewModel.swap(
            walletsProvider: restrictedWalletsProvider ?? .common(),
            initialSelectedItem: direction.tokenItem,
            initiallyExpandedAccount: initiallyExpandedAccount,
            preferredWalletId: preferredWalletId,
            showsBalanceFilter: showsBalanceFilter
        )

        return SwapTokenSelectorViewModel(
            swapDirection: direction,
            tokenSelectorViewModel: tokenSelectorViewModel,
            marketsTokensViewModel: restrictedWalletsProvider == nil ? marketsTokensViewModel : nil,
            output: output,
            tokenSelectorCoordinator: router,
            marketsTokenAdditionCoordinator: marketsTokenAdditionRouter
        )
    }

    private func resolveInitiallyExpandedAccount(for tappedToken: any SendSourceToken) -> TokenSelectorViewModel.InitiallyExpandedAccount? {
        let walletId = tappedToken.userWalletInfo.id

        guard let userWalletModel = userWalletRepository.models.first(where: { $0.userWalletId == walletId }) else {
            return nil
        }

        let cryptoAccount = userWalletModel.accountModelsManager.cryptoAccountModels.first { account in
            account.walletModelsManager.walletModels.contains { $0.id == tappedToken.id }
        }

        return cryptoAccount.map { .init(walletId: walletId, cryptoAccount: $0) }
    }
}
