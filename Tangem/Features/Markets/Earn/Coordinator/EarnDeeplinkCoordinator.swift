//
//  EarnDeeplinkCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import UIKit
import TangemUI

final class EarnDeeplinkCoordinator: ObservableObject {
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: FloatingSheetPresenter
    @Injected(\.earnAnalyticsProvider) private var earnAnalyticsProvider: EarnAnalyticsProvider

    @Published var tokenDetailsCoordinator: TokenDetailsCoordinator?
    @Published var yieldModulePromoCoordinator: YieldModulePromoCoordinator?
    @Published var yieldModuleActiveCoordinator: YieldModuleActiveCoordinator?

    private(set) var earnCoordinator: EarnCoordinator!

    private let earnType: EarnFilterType?
    private var yieldDeeplinkRouter: YieldDeeplinkRouter?

    init(earnType: EarnFilterType?, networkId: String?, dismissAction: @escaping () -> Void) {
        self.earnType = earnType

        earnCoordinator = EarnCoordinator(
            dismissAction: dismissAction,
            routeOnEarnTokenResolvedAction: { [weak self] resolution, source in
                self?.routeOnTokenResolved(resolution, source: source)
            }
        )

        let deeplinkFilter = EarnDataFilter(
            type: earnType ?? .all,
            networkIds: networkId.flatMap { [$0] }
        )

        earnCoordinator.start(with: .init(
            mostlyUsedTokens: nil,
            deeplinkFilter: deeplinkFilter,
            presentSource: .deeplink
        ))
    }

    func dismissTokenDetails() {
        tokenDetailsCoordinator = nil
    }
}

// MARK: - Private

private extension EarnDeeplinkCoordinator {
    func routeOnTokenResolved(_ resolution: EarnTokenResolution, source: EarnOpportunitySource) {
        switch resolution {
        case .toAdd(let token, let userWalletModels):
            openAddEarnToken(for: token, userWalletModels: userWalletModels, source: source)

        case .alreadyAdded(let walletModel, let userWalletModel):
            presentTokenDetails(by: walletModel, with: userWalletModel)
        }
    }

    func openAddEarnToken(
        for token: EarnTokenModel,
        userWalletModels: [any UserWalletModel],
        source: EarnOpportunitySource
    ) {
        earnAnalyticsProvider.logAddTokenScreenOpened(
            token: token.symbol,
            blockchain: token.networkName,
            source: source.rawValue
        )

        let configuration = EarnAddTokenFlowConfigurationFactory.make(
            earnToken: token,
            coordinator: self,
            analyticsProvider: earnAnalyticsProvider
        )

        Task { @MainActor in
            let viewModel = AddTokenFlowViewModel(
                userWalletModels: userWalletModels,
                configuration: configuration,
                coordinator: self
            )

            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }
}

// MARK: - EarnAddTokenRoutable

extension EarnDeeplinkCoordinator: EarnAddTokenRoutable {
    func presentTokenDetails(by walletModel: any WalletModel, with userWalletModel: any UserWalletModel) {
        let dismissAction: Action<Void> = { [weak self] _ in
            self?.tokenDetailsCoordinator = nil
        }

        guard let coordinator = MarketsMainTokenDetailsCoordinatorFactory.make(
            walletModel: walletModel,
            userWalletModel: userWalletModel,
            dismissAction: dismissAction
        ) else {
            return
        }

        tokenDetailsCoordinator = coordinator
    }

    /// In a yield-intent flow (`earn_type=yield`) a freshly added token routes straight to the
    /// Yield onboarding; otherwise it opens token details as usual. The yield routing itself
    /// falls back to token details when the Yield state can't be resolved.
    func presentAfterAdd(by walletModel: any WalletModel, with userWalletModel: any UserWalletModel) {
        guard earnType == .yield else {
            presentTokenDetails(by: walletModel, with: userWalletModel)
            return
        }

        openYieldOnboarding(walletModel: walletModel, userWalletModel: userWalletModel)
    }

    func close() {
        floatingSheetPresenter.removeActiveSheet()
    }

    func presentSuccessToast(with text: String) {
        Toast(view: SuccessToast(text: text))
            .present(
                layout: .top(padding: ToastConstants.topPadding),
                type: .temporary()
            )
    }

    func presentErrorToast(with text: String) {
        Toast(view: WarningToast(text: text))
            .present(
                layout: .top(padding: ToastConstants.topPadding),
                type: .temporary()
            )
    }
}

// MARK: - Yield onboarding

private extension EarnDeeplinkCoordinator {
    func openYieldOnboarding(walletModel: any WalletModel, userWalletModel: any UserWalletModel) {
        yieldDeeplinkRouter = YieldDeeplinkRouter(
            discardIncomingAction: { [weak self] in
                self?.presentTokenDetails(by: walletModel, with: userWalletModel)
            },
            openYieldPromoAction: { [weak self] apy, flowFactory in
                self?.openYieldModulePromoView(apy: apy, factory: flowFactory)
            },
            openYieldActiveAction: { [weak self] flowFactory in
                self?.openYieldModuleActiveInfo(factory: flowFactory)
            },
            onFinish: { [weak self] in
                self?.yieldDeeplinkRouter = nil
            }
        )

        yieldDeeplinkRouter?.handle(walletModel: walletModel, userWalletModel: userWalletModel)
    }

    func openYieldModulePromoView(apy: Decimal, factory: YieldModuleFlowFactory) {
        let dismissAction: Action<YieldModulePromoCoordinator.DismissOptions?> = { [weak self] option in
            self?.handleYieldDismiss(option)
        }

        yieldModulePromoCoordinator = factory.makeYieldPromoCoordinator(
            apy: apy,
            isApyBoostPromo: false,
            dismissAction: dismissAction
        )
    }

    func openYieldModuleActiveInfo(factory: YieldModuleFlowFactory) {
        let dismissAction: Action<YieldModuleActiveCoordinator.DismissOptions?> = { [weak self] option in
            self?.handleYieldDismiss(option)
        }

        yieldModuleActiveCoordinator = factory.makeYieldActiveCoordinator(dismissAction: dismissAction)
    }

    /// Mirrors `FeeCurrencyNavigating` (which this coordinator can't adopt — it isn't a
    /// `CoordinatorObject`): clears the active Yield screen and, when requested, opens token
    /// details for the fee currency.
    func handleYieldDismiss(_ option: FeeCurrencyNavigatingDismissOption?) {
        yieldModulePromoCoordinator = nil
        yieldModuleActiveCoordinator = nil

        guard
            let option,
            let result = try? WalletModelFinder.findWalletModel(
                userWalletId: option.userWalletId,
                tokenItem: option.tokenItem
            )
        else {
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.feeCurrencyNavigationDelay) { [weak self] in
            self?.presentTokenDetails(by: result.walletModel, with: result.userWalletModel)
        }
    }
}

// MARK: - Constants

private extension EarnDeeplinkCoordinator {
    enum ToastConstants {
        static let topPadding: CGFloat = 52
    }

    enum Constants {
        /// Lets the dismissed Yield screen finish its closing animation before the fee-currency
        /// token details are presented — without it SwiftUI may drop the new presentation that
        /// starts while the previous one is still dismissing. Mirrors `FeeCurrencyNavigating`
        /// (0.6), shortened a touch to feel snappier while still clearing the ~0.35s animation.
        static let feeCurrencyNavigationDelay: TimeInterval = 0.5
    }
}
