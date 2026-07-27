//
//  ForYouCoordinator+Swap.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemUI

@MainActor
extension ForYouCoordinator {
    func openTokenSummary(tokenItem: TokenItem, period: TokenSummaryPeriod) {
        let canGoToSwapPublisher = userWalletRepository.selectedModel
            .map { makeCanGoToSwapPublisher(of: tokenItem, in: $0) } ?? Just(false).eraseToAnyPublisher()

        tokenSummaryViewModel = TokenSummaryViewModel(
            tokenItem: tokenItem,
            period: period,
            canGoToSwapPublisher: canGoToSwapPublisher,
            onGoToSwap: { [weak self] in self?.goToSwap(with: tokenItem) },
            onClose: { [weak self] in self?.tokenSummaryViewModel = nil }
        )
    }

    func runPendingSwapAction() {
        guard let action = pendingSwapAction else {
            return
        }

        pendingSwapAction = nil
        Task { @MainActor in action() }
    }
}

private extension ForYouCoordinator {
    func goToSwap(with tokenItem: TokenItem) {
        guard let userWalletModel = userWalletRepository.selectedModel else {
            return
        }

        let holdings = swapAvailableHoldings(of: tokenItem, in: userWalletModel)

        switch holdings.count {
        case 0:
            return
        case 1:
            let walletModel = holdings[0]
            let userWalletInfo = userWalletModel.userWalletInfo
            pendingSwapAction = { [weak self] in
                self?.openSwap(walletModel: walletModel, userWalletInfo: userWalletInfo)
            }
        default:
            pendingSwapAction = { [weak self] in
                self?.presentSwapTokenSelector(with: tokenItem)
            }
        }

        // Dismissing the summary sheet fires the deferred action from its `onDismiss`.
        tokenSummaryViewModel = nil
    }

    /// A `nil` `currencyId` identifies no coin — matching on it would lump together every unmapped custom token.
    func coinHoldings(of tokenItem: TokenItem, in userWalletModel: any UserWalletModel) -> [any WalletModel] {
        guard let currencyId = tokenItem.currencyId else {
            return []
        }

        return AccountWalletModelsAggregator
            .walletModels(from: userWalletModel.accountModelsManager)
            .filter { $0.tokenItem.currencyId == currencyId }
    }

    func swapAvailableHoldings(of tokenItem: TokenItem, in userWalletModel: any UserWalletModel) -> [any WalletModel] {
        let userWalletInfo = userWalletModel.userWalletInfo

        return coinHoldings(of: tokenItem, in: userWalletModel)
            .filter { TokenActionAvailabilityProvider(userWalletInfo: userWalletInfo, walletModel: $0).isSwapAvailable }
    }

    func makeCanGoToSwapPublisher(of tokenItem: TokenItem, in userWalletModel: any UserWalletModel) -> AnyPublisher<Bool, Never> {
        let userWalletInfo = userWalletModel.userWalletInfo
        let holdings = coinHoldings(of: tokenItem, in: userWalletModel)

        let isAnySwapAvailable = {
            holdings.contains { TokenActionAvailabilityProvider(userWalletInfo: userWalletInfo, walletModel: $0).isSwapAvailable }
        }

        // `actionsUpdatePublisher` covers balance, staking, yield and the Express availability *cache*, but not
        // the Express update state, which `isSwapAvailable` also reads. The cache is published before the state
        // flips to `.updated`, so without the second source a token that came back unavailable-or-unlisted would
        // stay stuck on `.expressLoading` and leave the button disabled after the load finished.
        let expressStateUpdates = expressAvailabilityProvider.expressAvailabilityUpdateState
            .mapToVoid()
            .eraseToAnyPublisher()

        let updates: [AnyPublisher<Void, Never>] = holdings.map(\.actionsUpdatePublisher) + [expressStateUpdates]

        return Publishers.MergeMany(updates)
            .map { _ in isAnySwapAvailable() }
            .prepend(isAnySwapAvailable())
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    @MainActor
    func openSwap(walletModel: any WalletModel, userWalletInfo: UserWalletInfo) {
        guard let parameters = SwapPredefinedParametersHelper().makeParameters(
            walletModel: walletModel,
            userWalletInfo: userWalletInfo,
            position: .automatic
        ) else {
            return
        }

        presentSwap(parameters: parameters)
    }

    @MainActor
    func presentSwap(parameters: PredefinedSwapParameters) {
        let dismissAction: Action<SendCoordinator.DismissOptions?> = { [weak self] _ in
            self?.sendCoordinator = nil
        }

        tangemStoriesPresenter.present(
            story: .swap(.initialWithoutImages),
            analyticsSource: .markets,
            presentCompletion: { [weak self] in
                guard let self else { return }
                let coordinator = SendCoordinator(dismissAction: dismissAction, popToRootAction: popToRootAction)
                coordinator.start(with: .init(type: .swap(parameters), source: .markets))
                sendCoordinator = coordinator
            }
        )
    }

    func presentSwapTokenSelector(with tokenItem: TokenItem) {
        guard let userWalletModel = userWalletRepository.selectedModel else {
            return
        }

        swapTokenSelectorViewModel = ForYouSwapTokenSelectorViewModel(
            coin: tokenItem,
            walletId: userWalletModel.userWalletId,
            onSelect: { [weak self] walletModel, userWalletInfo in
                guard let self else { return }
                pendingSwapAction = { [weak self] in
                    self?.openSwap(walletModel: walletModel, userWalletInfo: userWalletInfo)
                }
                swapTokenSelectorViewModel = nil
            },
            onClose: { [weak self] in self?.swapTokenSelectorViewModel = nil }
        )
    }
}
