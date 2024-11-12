//
//  ActionButtonsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation

typealias ActionButtonsRoutable = ActionButtonsBuyFlowRoutable & ActionButtonsSellFlowRoutable & ActionButtonsSwapFlowRoutable

final class ActionButtonsViewModel: ObservableObject {
    @Injected(\.exchangeService) private var exchangeService: ExchangeService

    @Published private(set) var isButtonsDisabled = false

    // MARK: - Button ViewModels

    let buyActionButtonViewModel: BuyActionButtonViewModel
    let sellActionButtonViewModel = BaseActionButtonViewModel(model: .sell)
    let swapActionButtonViewModel = BaseActionButtonViewModel(model: .swap)

    private var bag = Set<AnyCancellable>()

    private let expressTokensListAdapter: ExpressTokensListAdapter

    init(
        coordinator: some ActionButtonsRoutable,
        expressTokensListAdapter: some ExpressTokensListAdapter,
        userWalletModel: some UserWalletModel
    ) {
        self.expressTokensListAdapter = expressTokensListAdapter

        buyActionButtonViewModel = BuyActionButtonViewModel(
            model: .buy,
            coordinator: coordinator,
            userWalletModel: userWalletModel
        )

        bind()
        fetchData()
    }

    func fetchData() {
        TangemFoundation.runTask(in: self) {
            async let _ = $0.fetchSwapData()
        }
    }
}

// MARK: - Bind

private extension ActionButtonsViewModel {
    func bind() {
        bindWalletModels()
        bindAvailableExchange()
    }

    func bindWalletModels() {
        expressTokensListAdapter
            .walletModels()
            .map(\.isEmpty)
            .assign(to: \.isButtonsDisabled, on: self, ownership: .weak)
            .store(in: &bag)
    }

    func bindAvailableExchange() {
        exchangeService
            .initializationPublisher
            .withWeakCaptureOf(self)
            .sink { viewModel, isExchangeAvailable in
                TangemFoundation.runTask(in: viewModel) { viewModel in
                    if isExchangeAvailable {
                        await viewModel.sellActionButtonViewModel.updateState(to: .idle)
                        await viewModel.buyActionButtonViewModel.updateState(to: .idle)
                    } else {
                        await viewModel.sellActionButtonViewModel.updateState(to: .initial)
                        await viewModel.buyActionButtonViewModel.updateState(to: .initial)
                    }
                }
            }
            .store(in: &bag)
    }
}

// MARK: - Swap

private extension ActionButtonsViewModel {
    func fetchSwapData() async {
        // [REDACTED_INFO]
    }
}

// MARK: - Sell

private extension ActionButtonsViewModel {
    func fetchSellData() async {
        // [REDACTED_INFO]
    }
}
