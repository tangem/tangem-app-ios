//
//  FeedSearchRouter.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation

protocol FeedSearchRoutable: AnyObject {
    func openToken(_ token: MarketsTokenModel)
}

final class FeedSearchRouter {
    private weak var navigation: (any FeedNavigation)?

    private let popToRootAction: Action<PopToRootOptions>

    init(context: FeedContext) {
        navigation = context.navigation
        popToRootAction = context.popToRootAction
    }
}

// MARK: - FeedSearchRoutable

extension FeedSearchRouter: FeedSearchRoutable {
    func openToken(_ token: MarketsTokenModel) {
        let coordinator = MarketsTokenDetailsCoordinator(
            dismissAction: { [weak self] _ in self?.navigation?.pop() },
            popToRootAction: popToRootAction
        )

        coordinator.start(with: .init(info: token, style: .marketsSheet))
        navigation?.push(.token(coordinator))
    }
}
