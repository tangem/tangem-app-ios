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

    private(set) var earnCoordinator: EarnCoordinator!

    init(earnType: EarnFilterType?, networkId: String?, dismissAction: @escaping () -> Void) {
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

// MARK: - Constants

private extension EarnDeeplinkCoordinator {
    enum ToastConstants {
        static let topPadding: CGFloat = 52
    }
}
