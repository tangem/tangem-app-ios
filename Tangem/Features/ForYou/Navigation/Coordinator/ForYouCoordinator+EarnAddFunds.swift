//
//  ForYouCoordinator+EarnAddFunds.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation
import TangemLocalization
import TangemUI

@MainActor
extension ForYouCoordinator {
    typealias Holding = EarnAddFundsHoldingsAggregator.Holding

    /// A suggested earn token already held in the portfolio tops up an existing holding instead of the add-token flow.
    /// One holding → the per-token Add funds sheet directly; several → a selector scoped to that coin.
    func openEarnAddFunds(holdings: [Holding]) {
        guard let first = holdings.first else {
            return
        }

        guard holdings.count == 1 else {
            return presentAddFundsTokenSelector(holdings: holdings)
        }

        presentAddFunds(walletModel: first.walletModel, userWalletModel: first.userWalletModel)
    }
}

extension ForYouCoordinator {
    // MARK: - Add funds presentation

    @MainActor
    func presentAddFundsTokenSelector(holdings: [Holding]) {
        floatingSheetPresenter.enqueue(
            sheet: ForYouAddFundsTokenSelectorViewModel(
                title: Localization.commonAddFunds,
                subtitle: Localization.commonChooseToken,
                holdings: holdings,
                selectionAction: { [weak self] walletModel, userWalletModel in
                    guard let self else { return }
                    // Replace the selector floating sheet with the per-token Add funds sheet.
                    floatingSheetPresenter.removeActiveSheet()
                    presentAddFunds(walletModel: walletModel, userWalletModel: userWalletModel)
                },
                closeAction: { [weak self] in
                    self?.floatingSheetPresenter.removeActiveSheet()
                }
            )
        )
    }

    @MainActor
    func presentAddFunds(walletModel: any WalletModel, userWalletModel: any UserWalletModel) {
        let viewModel = AddFundsViewModel(
            input: .init(
                mode: .sheet(.full),
                primaryAction: .hidden,
                walletModel: walletModel,
                userWalletModel: userWalletModel
            ),
            coordinator: self
        )
        floatingSheetPresenter.enqueue(sheet: viewModel)
    }
}

// MARK: - AddFundsRoutable

@MainActor
extension ForYouCoordinator: AddFundsRoutable {
    func addFundsRequestBuy(walletModel: any WalletModel, userWalletModel: any UserWalletModel) {
        floatingSheetPresenter.removeActiveSheet()

        let sourceToken = CommonSendTransferableTokenFactory(
            userWalletInfo: userWalletModel.userWalletInfo,
            walletModel: walletModel
        ).makeTransferableToken()

        let coordinator = SendCoordinator(dismissAction: { [weak self] _ in self?.sendCoordinator = nil })
        coordinator.start(with: .init(type: .onramp(sourceToken, parameters: .none), source: .markets))
        sendCoordinator = coordinator
    }

    func addFundsRequestSwap(walletModel: any WalletModel, userWalletModel: any UserWalletModel) {
        floatingSheetPresenter.removeActiveSheet()
        openSwap(walletModel: walletModel, userWalletInfo: userWalletModel.userWalletInfo)
    }

    func addFundsRequestReceive(viewModel: ReceiveMainViewModel) {
        // Dismiss the active Add funds sheet first, otherwise Receive is queued behind it and never shown.
        floatingSheetPresenter.removeActiveSheet()
        floatingSheetPresenter.enqueue(sheet: viewModel)
    }

    func addFundsRequestGoToToken(walletModel: any WalletModel, userWalletModel: any UserWalletModel) {
        // Add funds is presented with a `.hidden` primary action, so this is unreachable; dismiss defensively.
        floatingSheetPresenter.removeActiveSheet()
    }

    func addFundsClose() {
        floatingSheetPresenter.removeActiveSheet()
    }
}
