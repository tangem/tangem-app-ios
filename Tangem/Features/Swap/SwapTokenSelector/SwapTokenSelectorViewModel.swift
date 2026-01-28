//
//  SwapTokenSelectorViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress
import TangemLocalization
import TangemFoundation

final class SwapTokenSelectorViewModel: ObservableObject, Identifiable {
    // MARK: - View

    let tokenSelectorViewModel: AccountsAwareTokenSelectorViewModel
    let externalSearchViewModel: ExpressExternalSearchViewModel?

    // MARK: - Dependencies

    private let swapDirection: SwapDirection
    private let expressInteractor: ExpressInteractor
    private let expressPairsRepository: ExpressPairsRepository
    private let userWalletInfo: UserWalletInfo
    private weak var coordinator: SwapTokenSelectorRoutable?

    private var selectedTokenItem: TokenItem?

    init(
        swapDirection: SwapDirection,
        tokenSelectorViewModel: AccountsAwareTokenSelectorViewModel,
        externalSearchViewModel: ExpressExternalSearchViewModel?,
        expressInteractor: ExpressInteractor,
        expressPairsRepository: ExpressPairsRepository,
        userWalletInfo: UserWalletInfo,
        coordinator: SwapTokenSelectorRoutable
    ) {
        self.swapDirection = swapDirection
        self.tokenSelectorViewModel = tokenSelectorViewModel
        self.externalSearchViewModel = externalSearchViewModel
        self.expressInteractor = expressInteractor
        self.expressPairsRepository = expressPairsRepository
        self.userWalletInfo = userWalletInfo
        self.coordinator = coordinator

        tokenSelectorViewModel.setup(directionPublisher: Just(swapDirection).eraseToOptional())
        tokenSelectorViewModel.setup(with: self)

        externalSearchViewModel?.setup(searchTextPublisher: tokenSelectorViewModel.$searchText)
        externalSearchViewModel?.setup(selectionHandler: self)
    }

    func close() {
        coordinator?.closeSwapTokenSelector()
    }

    func onDisappear() {
        if let tokenItem = selectedTokenItem {
            Analytics.log(
                event: .swapChooseTokenScreenResult,
                params: [
                    .tokenChosen: Analytics.ParameterValue.yes.rawValue,
                    .token: tokenItem.currencySymbol,
                ]
            )
        } else {
            Analytics.log(
                event: .swapChooseTokenScreenResult,
                params: [.tokenChosen: Analytics.ParameterValue.no.rawValue]
            )
        }
    }
}

// MARK: - AccountsAwareTokenSelectorViewModelOutput

extension SwapTokenSelectorViewModel: AccountsAwareTokenSelectorViewModelOutput {
    func usedDidSelect(item: AccountsAwareTokenSelectorItem) {
        let expressInteractorWallet = ExpressInteractorWalletModelWrapper(
            userWalletInfo: item.userWalletInfo,
            walletModel: item.walletModel,
            expressOperationType: .swap
        )

        switch swapDirection {
        case .fromSource:
            expressInteractor.update(destination: expressInteractorWallet)
        case .toDestination:
            expressInteractor.update(sender: expressInteractorWallet)
        }

        selectedTokenItem = item.walletModel.tokenItem
        coordinator?.closeSwapTokenSelector()
    }
}

// MARK: - ExpressExternalTokenSelectionHandler

extension SwapTokenSelectorViewModel: ExpressExternalTokenSelectionHandler {
    func didSelectExternalToken(_ token: MarketsTokenModel) {
        Task { @MainActor in
            // For now, skip pair validation since we don't have network info from Markets API
            // The add-token flow will handle network selection

            // Proceed with add-token flow
            coordinator?.openAddTokenFlowForExpress(
                coinId: token.id,
                coinName: token.name,
                coinSymbol: token.symbol,
                swapDirection: swapDirection,
                userWalletInfo: userWalletInfo,
                completion: { [weak self] tokenItem, account in
                    self?.handleTokenAdded(tokenItem: tokenItem, account: account)
                }
            )
        }
    }

    private func handleTokenAdded(tokenItem: TokenItem, account: any CryptoAccountModel) {
        // Find newly created WalletModel
        guard let walletModel = account.walletModelsManager.walletModels
            .first(where: { $0.tokenItem == tokenItem }) else {
            return
        }

        // Get the userWalletInfo for the account
        let expressInteractorWallet = ExpressInteractorWalletModelWrapper(
            userWalletInfo: userWalletInfo,
            walletModel: walletModel,
            expressOperationType: .swap
        )

        switch swapDirection {
        case .fromSource:
            expressInteractor.update(destination: expressInteractorWallet)
        case .toDestination:
            expressInteractor.update(sender: expressInteractorWallet)
        }

        selectedTokenItem = tokenItem
        coordinator?.closeSwapTokenSelector()
    }
}

extension SwapTokenSelectorViewModel {
    typealias SwapDirection = AccountsAwareTokenSelectorItemSwapAvailabilityProvider.SwapDirection
}

extension SwapTokenSelectorViewModel.SwapDirection {
    var tokenItem: TokenItem {
        switch self {
        case .fromSource(let tokenItem): tokenItem
        case .toDestination(let tokenItem): tokenItem
        }
    }
}
