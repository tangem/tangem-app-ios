//
//  FeedCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemFoundation

final class FeedCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    @Published private(set) var rootViewModel: FeedViewModel?
    @Published var path: [FeedDestination] = []

    let shtorkaStateObject = MainShtorkaStateObject()

    // MARK: - Child sheets

    @Published var portfolioTokenList: MarketsPortfolioTokenListViewModel?

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        rootViewModel = FeedViewModelFactory().makeViewModel(coordinator: self)
    }

    private func pop() {
        _ = path.popLast()
    }
}

// MARK: - Options

extension FeedCoordinator {
    struct Options {}
}

// MARK: - FeedRoutable

extension FeedCoordinator: FeedRoutable {
    func openToken(_ token: MarketsTokenModel) {
        let coordinator = MarketsTokenDetailsCoordinator(
            dismissAction: { [weak self] _ in self?.pop() },
            popToRootAction: popToRootAction
        )

        coordinator.start(with: .init(info: token, style: .marketsSheet))
        path.append(.token(coordinator))
    }

    func openPortfolioToken(_ walletModel: any WalletModel) {
        guard
            let userWalletModel = userWalletRepository.models[walletModel.userWalletId],
            let accountModel = walletModel.account
        else {
            return
        }

        let coordinator = TokenDetailsCoordinator(
            dismissAction: { [weak self] _ in self?.pop() },
            popToRootAction: popToRootAction
        )

        coordinator.start(
            with: .init(
                userWalletInfo: userWalletModel.userWalletInfo,
                keysDerivingInteractor: userWalletModel.keysDerivingInteractor,
                walletModelsManager: accountModel.walletModelsManager,
                userTokensManager: accountModel.userTokensManager,
                addressBookManager: userWalletModel.addressBookManager,
                walletModel: walletModel,
                presentSource: .markets
            )
        )
        path.append(.portfolioToken(coordinator))
    }

    func choosePortfolioToken(from walletModels: [any WalletModel]) {
        portfolioTokenList = MarketsPortfolioTokenListViewModel(
            walletModels: walletModels,
            onSelect: { [weak self] walletModel in self?.openPortfolioToken(walletModel) },
            coordinator: self
        )
    }

    func returnToRoot() {
        guard path.isNotEmpty || rootViewModel?.searchViewModel.isActive == true else {
            return
        }

        withTransaction(.withoutAnimations()) {
            path.removeAll()
            portfolioTokenList = nil
            rootViewModel?.searchViewModel.reset()
        }
    }
}

// MARK: - MarketsPortfolioTokenListRoutable

extension FeedCoordinator: MarketsPortfolioTokenListRoutable {
    func closePortfolioTokenList() {
        portfolioTokenList = nil
    }
}
