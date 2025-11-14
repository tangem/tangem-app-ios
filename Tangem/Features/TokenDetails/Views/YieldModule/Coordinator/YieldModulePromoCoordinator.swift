//
//  YieldModulePromoCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

final class YieldModulePromoCoordinator: CoordinatorObject {
    // MARK: - Injected

    @Injected(\.floatingSheetPresenter)
    private var floatingSheetPresenter: any FloatingSheetPresenter

    @Injected(\.safariManager)
    private var safariManager: any SafariManager

    // MARK: - Propeties

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    @Published
    var rootViewModel: YieldModulePromoViewModel? = nil

    private weak var feeCurrencyNavigator: (any SendFeeCurrencyNavigating)?

    // MARK: - Init

    required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    // MARK: - Public Implementation

    func openUrl(url: URL) {
        safariManager.openURL(url)
    }

    func start(with options: Options) {
        rootViewModel = options.viewModel
        feeCurrencyNavigator = options.feeCurrencyNavigator
    }

    func openBottomSheet(viewModel: YieldModuleStartViewModel) {
        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openFeeCurrency(for feeWalletModel: any WalletModel, userWalletModel: any UserWalletModel) {
        feeCurrencyNavigator?.openFeeCurrency(for: feeWalletModel, userWalletModel: userWalletModel)
    }

    func dismiss() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
            dismissAction(())
        }
    }
}

// MARK: - Options

extension YieldModulePromoCoordinator {
    struct Options {
        let viewModel: YieldModulePromoViewModel
        let feeCurrencyNavigator: (any SendFeeCurrencyNavigating)?
    }
}
