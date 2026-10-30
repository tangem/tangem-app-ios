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
    func openCategoryFilter(with input: RealAssetsCategoryFilterInput)
}

final class RealAssetsFeedRouter {
    private weak var navigation: (any FeedNavigation)?

    private let popToRootAction: Action<PopToRootOptions>

    init(context: FeedContext) {
        navigation = context.navigation
        popToRootAction = context.popToRootAction
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

    func openCategoryFilter(with input: RealAssetsCategoryFilterInput) {
        Task { @MainActor [weak self] in
            let viewModel = MarketsRealAssetsFilterBottomSheetViewModel(
                input: input,
                onDismiss: { [weak self] in self?.navigation?.dismissModal() }
            )

            self?.navigation?.presentModal(.realAssetsCategoryFilter(viewModel))
        }
    }
}
