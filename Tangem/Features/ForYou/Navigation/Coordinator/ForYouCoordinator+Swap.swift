//
//  ForYouCoordinator+Swap.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation
import TangemLocalization
import TangemUI

@MainActor
extension ForYouCoordinator {
    func openTokenSummary(tokenItem: TokenItem, period: TokenSummaryPeriod) {
        let holdings = TokenSummaryPrimaryActionProvider.coinHoldings(of: tokenItem, in: userWalletRepository.models)

        tokenSummaryViewModel = TokenSummaryViewModel(
            tokenItem: tokenItem,
            period: period,
            primaryActionPublisher: TokenSummaryPrimaryActionProvider.makePublisher(
                balanceProviders: holdings.map(\.availableBalanceProvider)
            ),
            analyticsLogger: CommonTokenSummaryAnalyticsLogger(tokenItem: tokenItem),
            onPrimaryAction: { [weak self] kind in self?.handleTokenSummaryAction(kind, tokenItem: tokenItem) },
            onClose: { [weak self] in self?.tokenSummaryViewModel = nil }
        )
    }

    func tokenSummaryDidDismiss() {
        let action = tokenSummaryFollowUpAction
        tokenSummaryFollowUpAction = nil

        guard let action else {
            return
        }

        Task { @MainActor in action() }
    }

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
}

// MARK: - Token summary primary action

private extension ForYouCoordinator {
    func handleTokenSummaryAction(_ kind: TokenSummaryPrimaryAction.Kind, tokenItem: TokenItem) {
        switch kind {
        case .goToSwap:
            goToSwap(with: tokenItem)
        case .addFunds:
            addFunds(with: tokenItem)
        }
    }
}

// MARK: - Go to swap

private extension ForYouCoordinator {
    func goToSwap(with tokenItem: TokenItem) {
        let holdings = TokenSummaryPrimaryActionProvider.fundedHoldings(of: tokenItem, in: userWalletRepository.models)

        switch holdings.count {
        case 0:
            return
        case 1:
            let walletModel = holdings[0]
            tokenSummaryFollowUpAction = { [weak self] in self?.openSwapFromTokenSummary(walletModel: walletModel) }
        default:
            tokenSummaryFollowUpAction = { [weak self] in self?.presentSwapTokenSelector(with: tokenItem) }
        }

        // The follow-up fires from the summary sheet's `onDismiss`, so it runs only after the sheet is fully gone.
        tokenSummaryViewModel = nil
    }

    /// Kept in the coordinator rather than the view model: it decides whether the swap can happen at all, and the
    /// unavailability alert it raises needs the presenter.
    @MainActor
    func openSwapFromTokenSummary(walletModel: any WalletModel) {
        guard let userWalletModel = userWalletRepository.models[walletModel.userWalletId] else {
            return
        }

        let userWalletInfo = userWalletModel.userWalletInfo
        let availabilityProvider = TokenActionAvailabilityProvider(userWalletInfo: userWalletInfo, walletModel: walletModel)

        guard availabilityProvider.isSwapAvailable else {
            if let alert = TokenActionAvailabilityAlertBuilder().alert(for: availabilityProvider.swapAvailability) {
                alertPresenter.present(alert: alert)
            }
            return
        }

        openSwap(walletModel: walletModel, userWalletInfo: userWalletInfo)
    }

    @MainActor
    func presentSwapTokenSelector(with tokenItem: TokenItem) {
        guard let currencyId = tokenItem.currencyId else {
            return
        }

        let holdings = EarnAddFundsHoldingsAggregator.aggregate(
            currencyId: currencyId,
            in: userWalletRepository.models
        )

        let viewModel = ForYouAddFundsTokenSelectorViewModel(
            title: Localization.tokenSummaryGoToSwapButton,
            subtitle: Localization.commonChooseToken,
            holdings: holdings,
            selectionAction: { [weak self] walletModel, userWalletModel in
                guard let self else { return }
                floatingSheetPresenter.removeActiveSheet()

                // Mirrors Markets: a funded holding goes to swap, an empty one offers a top up.
                if walletModel.availableBalanceProvider.isFunded {
                    openSwapFromTokenSummary(walletModel: walletModel)
                } else {
                    presentAddFunds(walletModel: walletModel, userWalletModel: userWalletModel)
                }
            },
            closeAction: { [weak self] in self?.floatingSheetPresenter.removeActiveSheet() }
        )

        floatingSheetPresenter.enqueue(sheet: viewModel)
    }

    @MainActor
    func presentSwap(parameters: PredefinedSwapParameters) {
        tangemStoriesPresenter.present(
            story: .swap(.initialWithoutImages),
            analyticsSource: .markets,
            presentCompletion: { [weak self] in
                guard let self else { return }
                let coordinator = makeSendCoordinator()
                coordinator.start(with: .init(type: .swap(parameters), source: .markets))
                sendCoordinator = coordinator
            }
        )
    }
}

// MARK: - SendFeeCurrencyNavigating

extension ForYouCoordinator: SendFeeCurrencyNavigating {
    /// The portfolio destination is the same token details screen the protocol pushes.
    var tokenDetailsCoordinator: TokenDetailsCoordinator? {
        get { portfolioTokenDetailsCoordinator }
        set { portfolioTokenDetailsCoordinator = newValue }
    }
}

// MARK: - Add funds

private extension ForYouCoordinator {
    func addFunds(with tokenItem: TokenItem) {
        guard let currencyId = tokenItem.currencyId else {
            return
        }

        let holdings = EarnAddFundsHoldingsAggregator.aggregate(
            currencyId: currencyId,
            in: userWalletRepository.models
        )

        guard holdings.isNotEmpty else {
            return
        }

        tokenSummaryFollowUpAction = { [weak self] in self?.openEarnAddFunds(holdings: holdings) }
        tokenSummaryViewModel = nil
    }
}
