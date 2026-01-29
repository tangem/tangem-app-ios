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
    let marketsTokensViewModel: SwapMarketsTokensViewModel?

    // MARK: - Dependencies

    private let swapDirection: SwapDirection
    private let expressInteractor: ExpressInteractor
    private let tangemApiService: TangemApiService
    private weak var coordinator: SwapTokenSelectorRoutable?

    private var selectedTokenItem: TokenItem?

    init(
        swapDirection: SwapDirection,
        tokenSelectorViewModel: AccountsAwareTokenSelectorViewModel,
        marketsTokensViewModel: SwapMarketsTokensViewModel?,
        expressInteractor: ExpressInteractor,
        tangemApiService: TangemApiService,
        coordinator: SwapTokenSelectorRoutable
    ) {
        self.swapDirection = swapDirection
        self.tokenSelectorViewModel = tokenSelectorViewModel
        self.marketsTokensViewModel = marketsTokensViewModel
        self.expressInteractor = expressInteractor
        self.tangemApiService = tangemApiService
        self.coordinator = coordinator

        tokenSelectorViewModel.setup(directionPublisher: Just(swapDirection).eraseToOptional())
        tokenSelectorViewModel.setup(with: self)

        marketsTokensViewModel?.setup(searchTextPublisher: tokenSelectorViewModel.$searchText)
        marketsTokensViewModel?.setup(selectionHandler: self)
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

extension SwapTokenSelectorViewModel: SwapMarketsTokenSelectionHandler {
    func didSelectExternalToken(_ token: MarketsTokenModel) {
        Task { @MainActor in
            do {
                let networks = try await loadNetworks(for: token.id)

                guard !networks.isEmpty else {
                    return
                }

                let inputData = ExpressAddTokenInputData(
                    coinId: token.id,
                    coinName: token.name,
                    coinSymbol: token.symbol,
                    networks: networks,
                    swapDirection: swapDirection
                )

                coordinator?.openAddTokenFlowForExpress(inputData: inputData)
            } catch {
                AppLogger.error("Failed to load networks for coinId: \(token.id)", error: error)
            }
        }
    }

    private func loadNetworks(for coinId: String) async throws -> [NetworkModel] {
        let request = CoinsList.Request(
            supportedBlockchains: [],
            ids: [coinId]
        )

        let response = try await tangemApiService.loadCoins(requestModel: request)
        return response.coins.first?.networks ?? []
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
