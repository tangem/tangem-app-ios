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

    let dismissAction: Action<DismissOptions?>
    let popToRootAction: Action<PopToRootOptions>

    @Published
    var rootViewModel: YieldModuleActiveViewModel? = nil
    private var handle: SafariHandle?

    // MARK: - Init

    required init(dismissAction: @escaping Action<DismissOptions?>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    // MARK: - Public Implementation

    func start(with options: Options) {
        rootViewModel = options.viewModel
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

    func openFeeCurrency(walletModel: any WalletModel) {
        Task { @MainActor [weak self] in
            self?.floatingSheetPresenter.removeActiveSheet()
            self?.dismiss(with: .init(walletModel: walletModel))
        }
    }

    func closeBottomSheet() {
        Task { @MainActor [weak self] in
            self?.floatingSheetPresenter.removeActiveSheet()
        }
    }

    func dismiss() {
        Task { @MainActor [weak self] in
            self?.floatingSheetPresenter.removeActiveSheet()
            self?.dismiss(with: nil)
        }
    }

    // MARK: - Private Implementation

    @MainActor
    private func resumeBottomSheet() {
        floatingSheetPresenter.resumeSheetsDisplaying()
    }
}

// MARK: - Options

extension YieldModuleActiveCoordinator {
    struct Options {
        let viewModel: YieldModuleActiveViewModel
    }

    typealias DismissOptions = FeeCurrencyNavigatingDismissOption
}
