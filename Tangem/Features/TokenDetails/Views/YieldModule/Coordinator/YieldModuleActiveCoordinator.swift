//
//  YieldModuleActiveCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

final class YieldModuleActiveCoordinator: CoordinatorObject {
    // MARK: - Injected

    @Injected(\.floatingSheetPresenter)
    private var floatingSheetPresenter: any FloatingSheetPresenter

    @Injected(\.safariManager)
    private var safariManager: any SafariManager

    // MARK: - Propeties

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    @Published
    var rootViewModel: YieldModuleActiveViewModel? = nil
    private var handle: SafariHandle?

    // MARK: - Dependencies

    private weak var feeCurrencyNavigator: (any SendFeeCurrencyNavigating)?

    // MARK: - Init

    required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    // MARK: - Public Implementation

    func start(with options: Options) {
        rootViewModel = options.viewModel
        feeCurrencyNavigator = options.feeCurrencyNavigator
    }

    @MainActor
    func openUrl(url: URL) {
        floatingSheetPresenter.pauseSheetsDisplaying()
        handle = safariManager.openURL(
            url, configuration: .init(),
            onDismiss: resumeBottomSheet,
            onSuccess: { _ in
                self.resumeBottomSheet()
            }
        )
    }

    func openBottomSheet(viewModel: YieldModuleTransactionViewModel) {
        Task { @MainActor [weak self] in
            self?.floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openFeeCurrency(for feeWalletModel: any WalletModel, userWalletModel: any UserWalletModel) {
        feeCurrencyNavigator?.openFeeCurrency(for: feeWalletModel, userWalletModel: userWalletModel)
    }

    func closeBottomSheet() {
        Task { @MainActor [weak self] in
            self?.floatingSheetPresenter.removeActiveSheet()
        }
    }

    func dismiss() {
        Task { @MainActor [weak self] in
            self?.floatingSheetPresenter.removeActiveSheet()
            self?.dismissAction(())
        }
    }

    // MARK: - Private Implementation

    @MainActor
    private func pauseBottomSheet() {
        floatingSheetPresenter.pauseSheetsDisplaying()
    }

    @MainActor
    private func resumeBottomSheet() {
        floatingSheetPresenter.resumeSheetsDisplaying()
    }
}

// MARK: - Options

extension YieldModuleActiveCoordinator {
    struct Options {
        let viewModel: YieldModuleActiveViewModel
        let feeCurrencyNavigator: (any SendFeeCurrencyNavigating)?
    }
}
