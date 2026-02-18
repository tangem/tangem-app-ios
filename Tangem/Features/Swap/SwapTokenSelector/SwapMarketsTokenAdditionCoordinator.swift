//
//  SwapMarketsTokenAdditionCoordinator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemAccounts
import TangemUI
import UIKit

/// Coordinator that handles market token addition flow in swap context.
/// Encapsulates shared logic for adding tokens from markets search.
final class SwapMarketsTokenAdditionCoordinator {
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: FloatingSheetPresenter
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    private let source: SwapSelectTokenAnalyticsLogger.SwapTokenSource
    private let onTokenAdded: (AccountsAwareTokenSelectorItem) -> Void

    init(
        source: SwapSelectTokenAnalyticsLogger.SwapTokenSource = .markets,
        onTokenAdded: @escaping (AccountsAwareTokenSelectorItem) -> Void
    ) {
        self.source = source
        self.onTokenAdded = onTokenAdded
    }
}

extension SwapMarketsTokenAdditionCoordinator: SwapMarketsTokenAdditionRoutable {
    @MainActor
    func requestAddToken(inputData: ExpressAddTokenInputData) {
        UIApplication.shared.endEditing()

        guard !inputData.networks.isEmpty else {
            return
        }

        // Create configuration
        let configuration = SwapAddMarketsTokenFlowConfigurationFactory.make(
            coinId: inputData.coinId,
            coinName: inputData.coinName,
            coinSymbol: inputData.coinSymbol,
            networks: inputData.networks,
            source: source,
            userHasSearchedDuringThisSession: inputData.userHasSearchedDuringThisSession,
            additionRoutable: self
        )

        // Present add token flow
        let viewModel = AccountsAwareAddTokenFlowViewModel(
            userWalletModels: userWalletRepository.models,
            configuration: configuration,
            coordinator: self
        )

        floatingSheetPresenter.enqueue(sheet: viewModel)
    }

    @MainActor
    func didAddMarketToken(item: AccountsAwareTokenSelectorItem) async {
        floatingSheetPresenter.removeActiveSheet()

        // Add a small delay to avoid animation glitches
        try? await Task.sleep(for: .milliseconds(500))

        onTokenAdded(item)
    }
}

extension SwapMarketsTokenAdditionCoordinator: AccountsAwareAddTokenFlowRoutable {
    func close() {
        floatingSheetPresenter.removeActiveSheet()
    }

    func presentSuccessToast(with text: String) {
        Toast(view: SuccessToast(text: text))
            .present(
                layout: .top(padding: Constants.toastTopPadding),
                type: .temporary()
            )
    }

    func presentErrorToast(with text: String) {
        Toast(view: WarningToast(text: text))
            .present(
                layout: .top(padding: Constants.toastTopPadding),
                type: .temporary()
            )
    }
}

// MARK: - Constants

private extension SwapMarketsTokenAdditionCoordinator {
    enum Constants {
        static let toastTopPadding: CGFloat = 52
    }
}
