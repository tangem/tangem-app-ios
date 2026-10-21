//
//  SwapTokenSelectorViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdk
import TangemExpress
import TangemLocalization
import TangemFoundation

protocol SwapTokenSelectorOutput: AnyObject {
    func swapTokenSelectorDidRequestUpdate(sender item: TokenSelectorItem) throws
    func swapTokenSelectorDidRequestUpdate(destination item: TokenSelectorItem) throws
}

final class SwapTokenSelectorViewModel: ObservableObject, Identifiable {
    // MARK: - View

    let tokenSelectorViewModel: TokenSelectorViewModel
    let marketsTokensViewModel: SwapMarketsTokensViewModel?
    let offeredTokensViewModel: SwapOfferedTokensViewModel?

    // MARK: - Dependencies

    private let swapDirection: SwapDirection
    private weak var output: SwapTokenSelectorOutput?

    private weak var tokenSelectorCoordinator: SwapTokenSelectorRoutable?
    private weak var marketsTokenAdditionCoordinator: SwapMarketsTokenAdditionRoutable?

    @Injected(\.alertPresenter) private var alertPresenter: any AlertPresenter

    private var selectedTokenItem: TokenItem?

    // MARK: - Computed

    /// Returns true if user has searched during this session
    var userHasSearchedDuringThisSession: Bool {
        marketsTokensViewModel?.userHasSearchedDuringThisSession ?? false
    }

    init(
        swapDirection: SwapDirection,
        tokenSelectorViewModel: TokenSelectorViewModel,
        marketsTokensViewModel: SwapMarketsTokensViewModel?,
        offeredTokensViewModel: SwapOfferedTokensViewModel?,
        output: SwapTokenSelectorOutput?,
        tokenSelectorCoordinator: SwapTokenSelectorRoutable,
        marketsTokenAdditionCoordinator: SwapMarketsTokenAdditionRoutable
    ) {
        self.swapDirection = swapDirection
        self.tokenSelectorViewModel = tokenSelectorViewModel
        self.marketsTokensViewModel = marketsTokensViewModel
        self.offeredTokensViewModel = offeredTokensViewModel
        self.output = output
        self.tokenSelectorCoordinator = tokenSelectorCoordinator
        self.marketsTokenAdditionCoordinator = marketsTokenAdditionCoordinator

        tokenSelectorViewModel.setup(directionPublisher: Just(swapDirection).eraseToOptional())
        tokenSelectorViewModel.setup(with: self)

        marketsTokensViewModel?.setup(searchTextPublisher: tokenSelectorViewModel.$searchText)
        offeredTokensViewModel?.setup(displayedWalletIdPublisher: tokenSelectorViewModel.$selectedChipId)
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

    func selectNewToken(_ item: TokenSelectorItem) {
        selectToken(item)
    }
}

// MARK: - TokenSelectorViewModelOutput

extension SwapTokenSelectorViewModel: TokenSelectorViewModelOutput {
    func userDidSelect(item: TokenSelectorItem) {
        guard selectToken(item) else {
            return
        }

        logPortfolioTokenSelected(item: item)
    }
}

// MARK: - Private

private extension SwapTokenSelectorViewModel {
    func logPortfolioTokenSelected(item: TokenSelectorItem) {
        let analyticsLogger = SwapSelectTokenAnalyticsLogger(
            source: .portfolio,
            userHasSearchedDuringThisSession: false
        )
        analyticsLogger.logTokenSelected(coinSymbol: item.tokenItem.currencySymbol)
    }

    @discardableResult
    func selectToken(_ item: TokenSelectorItem) -> Bool {
        do {
            switch swapDirection {
            case .fromSource:
                try output?.swapTokenSelectorDidRequestUpdate(destination: item)
            case .toDestination:
                try output?.swapTokenSelectorDidRequestUpdate(sender: item)
            }
        } catch {
            AppLogger.error(error: error)
            alertPresenter.present(alert: error.alertBinder)
            return false
        }

        selectedTokenItem = item.tokenItem

        // Defer dismissal to the next run loop iteration to avoid
        // destroying the sheet while SwiftUI's AttributeGraph is mid-update
        Task { @MainActor in
            tokenSelectorCoordinator?.closeSwapTokenSelector()
        }

        return true
    }
}

// MARK: - ExpressExternalTokenSelectionHandler

extension SwapTokenSelectorViewModel: SwapMarketsTokenSelectionHandler {
    func didSelectExternalToken(_ token: MarketsTokenModel) {
        Task { @MainActor in
            var networks = token.networks ?? []

            // L2 networks are not returned by the markets list, so append them for Ethereum only,
            // the same way token details does.
            if token.id == Blockchain.ethereum(testnet: false).coinId {
                let l2Items = SupportedBlockchains.l2Blockchains.map {
                    NetworkModel(networkId: $0.networkId, contractAddress: nil, decimalCount: nil)
                }

                networks.append(contentsOf: l2Items)
            }

            guard !networks.isEmpty else {
                AppLogger.error(error: "Selected tokens with no networks")
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
    typealias SwapDirection = TokenSelectorItemSwapAvailabilityProvider.SwapDirection
}

extension SwapTokenSelectorViewModel.SwapDirection {
    var tokenItem: WalletTokenItem? {
        switch self {
        case .fromSource(let item), .toDestination(let item):
            return item
        }
    }
}
