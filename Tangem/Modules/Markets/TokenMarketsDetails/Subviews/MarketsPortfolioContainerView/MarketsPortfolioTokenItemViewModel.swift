//
//  MarketsPortfolioTokenItemViewModel.swift
//  Tangem
//
//  Created by skibinalexander on 10.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class MarketsPortfolioTokenItemViewModel: ObservableObject, Identifiable {
    // MARK: - Public Properties

    @Published var fiatBalanceValue: String = ""
    @Published var balanceValue: String = ""
    @Published var contextActions: [TokenActionType] = []

    var id: WalletModel.ID {
        walletModel.id
    }

    var tokenIconInfo: TokenIconInfo {
        TokenIconInfoBuilder().build(from: walletModel.tokenItem, isCustom: walletModel.isCustom)
    }

    var tokenName: String {
        "\(walletModel.tokenItem.currencySymbol) \(walletModel.tokenItem.networkName)"
    }

    var walletModelId: WalletModel.ID {
        walletModel.id
    }

    let userWalletId: UserWalletId
    let walletName: String

    // MARK: - Private Properties

    private weak var walletModel: WalletModel!
    private weak var contextActionsProvider: MarketsPortfolioContextActionsProvider?
    private weak var contextActionsDelegate: MarketsPortfolioContextActionsDelegate?

    private var updateSubscription: AnyCancellable?

    // MARK: - Init

    init(
        userWalletId: UserWalletId,
        walletName: String,
        walletModel: WalletModel,
        contextActionsProvider: MarketsPortfolioContextActionsProvider?,
        contextActionsDelegate: MarketsPortfolioContextActionsDelegate?
    ) {
        self.userWalletId = userWalletId
        self.walletName = walletName
        self.walletModel = walletModel
        self.contextActionsProvider = contextActionsProvider
        self.contextActionsDelegate = contextActionsDelegate

        bind()
        buildContextActions()
    }

    func bind() {
        updateSubscription = walletModel?
            .walletDidChangePublisher
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, walletModelState in
                if walletModelState.isSuccessfullyLoaded {
                    viewModel.fiatBalanceValue = viewModel.walletModel?.fiatBalance ?? ""
                    viewModel.balanceValue = viewModel.walletModel?.balance ?? ""
                }
            }
    }

    func didTapContextAction(_ actionType: TokenActionType) {
        contextActionsDelegate?.didTapContextAction(actionType, for: self)
    }

    // MARK: - Private Implementation

    private func buildContextActions() {
        contextActions = contextActionsProvider?.buildContextActions(for: self) ?? []
    }
}
