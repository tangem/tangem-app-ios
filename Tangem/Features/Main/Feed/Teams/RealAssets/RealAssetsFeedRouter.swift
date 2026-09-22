//
//  RealAssetsFeedRouter.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation
import TangemUI

protocol RealAssetsFeedRoutable: AnyObject {
    func openToken(_ token: MarketsTokenModel)
    func openPortfolioToken(_ walletModel: any WalletModel)
    func openCategoryFilter(with input: RealAssetsCategoryFilterInput)
}

final class RealAssetsFeedRouter {
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: FloatingSheetPresenter

    private weak var navigation: (any FeedNavigation)?
    private weak var categoryFilter: MarketsRealAssetsFilterBottomSheetViewModel?

    private let popToRootAction: Action<PopToRootOptions>
    private let portfolioTokenRouter: FeedPortfolioTokenRouter

    init(context: FeedContext) {
        navigation = context.navigation
        popToRootAction = context.popToRootAction
        portfolioTokenRouter = FeedPortfolioTokenRouter(context: context)
    }
}

// MARK: - RealAssetsFeedRoutable

extension RealAssetsFeedRouter: RealAssetsFeedRoutable {
    func openToken(_ token: MarketsTokenModel) {
        let coordinator = MarketsTokenDetailsCoordinator(
            dismissAction: { [weak self] _ in self?.navigation?.pop() },
            popToRootAction: popToRootAction
        )

        coordinator.start(with: .init(info: token, style: .marketsSheet))
        navigation?.push(.token(coordinator))
    }

    func openPortfolioToken(_ walletModel: any WalletModel) {
        portfolioTokenRouter.open(walletModel)
    }

    func openCategoryFilter(with input: RealAssetsCategoryFilterInput) {
        Task { @MainActor [weak self] in
            guard let self, categoryFilter == nil else {
                return
            }

            let viewModel = MarketsRealAssetsFilterBottomSheetViewModel(
                input: input,
                onDismiss: { [weak self] in
                    self?.categoryFilter = nil
                    self?.floatingSheetPresenter.removeActiveSheet()
                }
            )

            categoryFilter = viewModel
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }
}
