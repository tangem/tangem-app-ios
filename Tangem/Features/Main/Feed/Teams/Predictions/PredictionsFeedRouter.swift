//
//  PredictionsFeedRouter.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol PredictionsFeedRoutable: AnyObject {
    func openPolymarketMain(wallet: UserWalletModel)
}

final class PredictionsFeedRouter: PredictionsFeedRoutable {
    private weak var navigation: (any FeedNavigation)?
    private weak var container: (any FeedContainer)?
    private let popToRootAction: Action<PopToRootOptions>

    init(context: FeedContext, container: any FeedContainer) {
        navigation = context.navigation
        self.container = container
        popToRootAction = context.popToRootAction
    }

    func openPolymarketMain(wallet: UserWalletModel) {
        guard let navigation, navigation.isAtRoot else { return }

        container?.expand()
        let coordinator = PolymarketCoordinator(
            dismissAction: { [weak self] in self?.navigation?.pop() },
            popToRootAction: popToRootAction
        )
        coordinator.start(with: .init(userWalletModel: wallet))
        navigation.push(.polymarket(coordinator))
    }
}
