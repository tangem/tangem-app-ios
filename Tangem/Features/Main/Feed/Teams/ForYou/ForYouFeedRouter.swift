//
//  ForYouFeedRouter.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol ForYouFeedRoutable: AnyObject {
    func openForYou()
}

final class ForYouFeedRouter: ForYouFeedRoutable {
    private weak var navigation: (any FeedNavigation)?
    private let popToRootAction: Action<PopToRootOptions>
    private let earnRouter: EarnFeedRouter

    init(context: FeedContext) {
        navigation = context.navigation
        popToRootAction = context.popToRootAction
        earnRouter = EarnFeedRouter(context: context)
    }

    func openForYou() {
        guard let navigation, navigation.isAtRoot else { return }

        let coordinator = ForYouCoordinator(
            dismissAction: { [weak self] _ in self?.navigation?.pop() },
            popToRootAction: popToRootAction,
            routeOnTokenResolvedAction: { [weak self] resolution, source in
                self?.earnRouter.routeOnTokenResolved(resolution, source: source)
            }
        )
        coordinator.start(with: .init())
        navigation.pushAfterSheetExpansion(.forYou(coordinator))
    }
}
