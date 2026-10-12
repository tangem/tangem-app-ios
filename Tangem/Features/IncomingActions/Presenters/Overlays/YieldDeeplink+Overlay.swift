//
//  YieldDeeplink+Overlay.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

extension YieldDeeplink: DeeplinkOverlayProviding {
    func makeOverlay(in context: DeeplinkOverlayContext) -> DeeplinkOverlayResult? {
        // A link that can't reach Yield mode lands on the Earn list, like any other Earn link.
        guard let target = findTarget() else {
            return .ready(context.sheet(context.makeEarnView(earnType: .yield, networkId: earnFallbackNetworkId)))
        }

        // Which of the two Yield screens the token opens is decided by the module state, which may still be
        // loading.
        return .whenReady {
            let destination = await YieldModuleDestinationResolver().resolve(
                walletModel: target.walletModel,
                userWalletModel: target.userWalletModel
            )

            return destination.flatMap { makeYieldOverlay(for: $0, in: context) }
        }
    }
}

// MARK: - Private

@MainActor
private extension YieldDeeplink {
    func makeYieldOverlay(for destination: YieldModuleDestination, in context: DeeplinkOverlayContext) -> OverlayView {
        switch destination {
        case .promo(let apy, let flowFactory):
            let coordinator = flowFactory.makeYieldPromoCoordinator(
                apy: apy,
                isApyBoostPromo: false,
                dismissAction: { option in
                    Task { @MainActor in finish(with: option, in: context) }
                }
            )

            return context.cover(context.embedInNavigationStack { YieldModulePromoCoordinatorView(coordinator: coordinator) })

        case .active(let flowFactory):
            let coordinator = flowFactory.makeYieldActiveCoordinator(
                dismissAction: { option in
                    Task { @MainActor in finish(with: option, in: context) }
                }
            )

            return context.sheet(YieldModuleActiveCoordinatorView(coordinator: coordinator))
        }
    }

    /// Does for a Yield screen shown over everything what `FeeCurrencyNavigating` does for one opened from a
    /// coordinator: closes it, and opens the fee currency it asks for once the closing is over.
    func finish(with option: FeeCurrencyNavigatingDismissOption?, in context: DeeplinkOverlayContext) {
        context.dismiss()

        guard
            let option,
            let result = try? WalletModelFinder.findWalletModel(userWalletId: option.userWalletId, tokenItem: option.tokenItem)
        else {
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.feeCurrencyNavigationDelay) {
            context.makeTokenDetailsOverlay(
                walletModel: result.walletModel,
                userWalletModel: result.userWalletModel,
                pendingTransactionDetails: nil,
                id: context.id + Constants.feeCurrencyIdSuffix
            )
            .map { context.present($0) }
        }
    }
}

// MARK: - Constants

private extension YieldDeeplink {
    enum Constants {
        /// Lets the dismissed Yield screen finish its closing animation before the fee-currency token details
        /// are presented — a presentation that starts while the previous one is still dismissing gets dropped.
        static let feeCurrencyNavigationDelay: TimeInterval = 0.5
        /// The fee currency is a screen of its own, so it takes an id of its own instead of replacing the
        /// Yield screen it came from.
        static let feeCurrencyIdSuffix = "/fee-currency"
    }
}
