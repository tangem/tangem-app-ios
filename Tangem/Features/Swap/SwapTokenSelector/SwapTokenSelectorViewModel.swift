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

protocol SwapTokenSelectorOutput: AnyObject {
    func swapTokenSelectorDidRequestUpdate(sender item: AccountsAwareTokenSelectorItem, isNewlyAddedFromMarkets: Bool)
    func swapTokenSelectorDidRequestUpdate(destination item: AccountsAwareTokenSelectorItem, isNewlyAddedFromMarkets: Bool)
}

final class SwapTokenSelectorViewModel: ObservableObject, Identifiable {
    // MARK: - View

    let tokenSelectorViewModel: AccountsAwareTokenSelectorViewModel
    let marketsTokensViewModel: SwapMarketsTokensViewModel?

    // MARK: - Dependencies

    private let swapDirection: SwapDirection
    private weak var output: SwapTokenSelectorOutput?

    private weak var tokenSelectorCoordinator: SwapTokenSelectorRoutable?
    private weak var marketsTokenAdditionCoordinator: SwapMarketsTokenAdditionRoutable?

    private var selectedTokenItem: TokenItem?

    // MARK: - Computed

    /// Returns true if user has searched during this session
    var userHasSearchedDuringThisSession: Bool {
        marketsTokensViewModel?.userHasSearchedDuringThisSession ?? false
    }

    init(
        swapDirection: SwapDirection,
        tokenSelectorViewModel: AccountsAwareTokenSelectorViewModel,
        marketsTokensViewModel: SwapMarketsTokensViewModel?,
        output: SwapTokenSelectorOutput?,
        tokenSelectorCoordinator: SwapTokenSelectorRoutable,
        marketsTokenAdditionCoordinator: SwapMarketsTokenAdditionRoutable
    ) {
        self.swapDirection = swapDirection
        self.tokenSelectorViewModel = tokenSelectorViewModel
        self.marketsTokensViewModel = marketsTokensViewModel
        self.output = output
        self.tokenSelectorCoordinator = tokenSelectorCoordinator
        self.marketsTokenAdditionCoordinator = marketsTokenAdditionCoordinator

        tokenSelectorViewModel.setup(directionPublisher: Just(swapDirection).eraseToOptional())
        tokenSelectorViewModel.setup(with: self)

        marketsTokensViewModel?.setup(searchTextPublisher: tokenSelectorViewModel.$searchText)
        marketsTokensViewModel?.setup(selectionHandler: self)
    }

    func close() {
        tokenSelectorCoordinator?.closeSwapTokenSelector()
    }

    func onAppear() {
        Analytics.log(.swapChooseTokenScreenOpened)
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

    func selectNewToken(_ item: AccountsAwareTokenSelectorItem) {
        selectToken(item, isNewlyAddedFromMarkets: true)
    }
}

// MARK: - AccountsAwareTokenSelectorViewModelOutput

extension SwapTokenSelectorViewModel: AccountsAwareTokenSelectorViewModelOutput {
    func userDidSelect(item: AccountsAwareTokenSelectorItem) {
        logPortfolioTokenSelected(item: item)
        selectToken(item, isNewlyAddedFromMarkets: false)
    }
}

// MARK: - Private

private extension SwapTokenSelectorViewModel {
    func selectToken(_ item: AccountsAwareTokenSelectorItem, isNewlyAddedFromMarkets: Bool) {
        switch swapDirection {
        case .fromSource:
            output?.swapTokenSelectorDidRequestUpdate(destination: item, isNewlyAddedFromMarkets: isNewlyAddedFromMarkets)
        case .toDestination:
            output?.swapTokenSelectorDidRequestUpdate(sender: item, isNewlyAddedFromMarkets: isNewlyAddedFromMarkets)
        }

        selectedTokenItem = item.tokenItem
        tokenSelectorCoordinator?.closeSwapTokenSelector()
    }

    func logPortfolioTokenSelected(item: AccountsAwareTokenSelectorItem) {
        let analyticsLogger = SwapSelectTokenAnalyticsLogger(
            source: .portfolio,
            userHasSearchedDuringThisSession: false
        )
        analyticsLogger.logTokenSelected(coinSymbol: item.tokenItem.currencySymbol)
    }
}

// MARK: - ExpressExternalTokenSelectionHandler

extension SwapTokenSelectorViewModel: SwapMarketsTokenSelectionHandler {
    func didSelectExternalToken(_ token: MarketsTokenModel) {
        Task { @MainActor in
            guard let networks = token.networks, !networks.isEmpty else {
                AppLogger.debug("Selected tokens with no networks")
                return
            }

            let inputData = ExpressAddTokenInputData(
                coinId: token.id,
                coinName: token.name,
                coinSymbol: token.symbol,
                networks: networks,
                userHasSearchedDuringThisSession: userHasSearchedDuringThisSession
            )

            marketsTokenAdditionCoordinator?.requestAddToken(inputData: inputData)
        }
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
