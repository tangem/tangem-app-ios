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

    // MARK: - Propeties

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    @Published
    var rootViewModel: YieldModulePromoViewModel? = nil

    private weak var feeCurrencyNavigator: (any FeeCurrencyNavigating)?

    // MARK: - Init

    required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    // MARK: - Public Implementation

    func start(with options: Options) {
        rootViewModel = .init(
            walletModel: options.walletModel,
            apy: options.apy,
            coordinator: self,
            startEarnAction: options.startEarnAction
        )

        feeCurrencyNavigator = options.feeCurrencyNavigator
    }

    func openRateInfoSheet(walletModel: any WalletModel) {
        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: YieldModuleStartViewModel(walletModel: walletModel, viewState: .rateInfo))
        }
    }

    func openStartEarningSheet(walletModel: any WalletModel, startEarnAction: @escaping () -> Void) {
        Task { @MainActor in
            floatingSheetPresenter.enqueue(
                sheet: YieldModuleStartViewModel(
                    walletModel: walletModel,
                    viewState: .startEarning,
                    openFeeCurrencyAction: { [weak self] feeWalletModel, selectedUserModel in
                        self?.feeCurrencyNavigator?.openFeeCurrency(for: feeWalletModel, userWalletModel: selectedUserModel)
                    },
                    startEarnAction: startEarnAction
                )
            )
        }
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
        let walletModel: any WalletModel
        let apy: String
        let feeCurrencyNavigator: any FeeCurrencyNavigating
        let startEarnAction: () -> Void
    }
}
