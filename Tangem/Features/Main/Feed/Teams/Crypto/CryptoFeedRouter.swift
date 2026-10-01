//
//  CryptoFeedRouter.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation
import TangemUI

protocol CryptoFeedRoutable: AnyObject {
    func openToken(_ token: MarketsTokenModel)
    func openPulseTagFilter(with input: PulseTagFilterInput)
    func openMarketCapInfo(subject: MarketCapInfoSubject)
    func openPortfolioToken(_ walletModel: any WalletModel)
}

final class CryptoFeedRouter {
    private weak var navigation: (any FeedNavigation)?

    private let popToRootAction: Action<PopToRootOptions>
    private let portfolioTokenRouter: FeedPortfolioTokenRouter

    init(context: FeedContext) {
        navigation = context.navigation
        popToRootAction = context.popToRootAction
        portfolioTokenRouter = FeedPortfolioTokenRouter(context: context)
    }
}

// MARK: - CryptoFeedRoutable

extension CryptoFeedRouter: CryptoFeedRoutable {
    func openToken(_ token: MarketsTokenModel) {
        let coordinator = MarketsTokenDetailsCoordinator(
            dismissAction: { [weak self] _ in self?.navigation?.pop() },
            popToRootAction: popToRootAction
        )

        coordinator.start(with: .init(info: token, style: .marketsSheet))
        navigation?.push(.token(coordinator))
    }

    func openPulseTagFilter(with input: PulseTagFilterInput) {
        Task { @MainActor [weak self] in
            let viewModel = PulseTagFilterBottomSheetViewModel(
                input: input,
                onDismiss: { [weak self] in self?.navigation?.dismissModal() }
            )

            self?.navigation?.presentModal(.pulseTagFilter(viewModel))
        }
    }

    func openMarketCapInfo(subject: MarketCapInfoSubject) {
        let viewModel = MarketCapInfoBottomSheetViewModel(
            subject: subject,
            closeAction: { [weak self] in self?.navigation?.dismissModal() }
        )

        navigation?.presentModal(.marketCapInfo(viewModel))
    }

    func openPortfolioToken(_ walletModel: any WalletModel) {
        portfolioTokenRouter.open(walletModel)
    }
}
