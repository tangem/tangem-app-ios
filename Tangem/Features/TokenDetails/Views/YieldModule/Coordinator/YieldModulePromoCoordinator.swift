//
//  YieldModulePromoCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class YieldModulePromoCoordinator: CoordinatorObject {
    // MARK: - Injected

    @Injected(\.floatingSheetPresenter)
    private var floatingSheetPresenter: any FloatingSheetPresenter

    @Injected(\.safariManager)
    private var safariManager: any SafariManager

    // MARK: - Propeties

    let dismissAction: Action<DismissOptions?>
    let popToRootAction: Action<PopToRootOptions>

    @Published
    var rootViewModel: YieldModulePromoViewModel? = nil

    // MARK: - Init

    required init(dismissAction: @escaping Action<DismissOptions?>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    // MARK: - Public Implementation

    func openUrl(url: URL) {
        safariManager.openURL(url)
    }

    func start(with options: Options) {
        rootViewModel = options.viewModel
    }

    func openBottomSheet(viewModel: YieldModuleStartViewModel) {
        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openFeeCurrency(walletModel: any WalletModel) {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
            dismiss(with: .init(userWalletId: walletModel.userWalletId, tokenItem: walletModel.feeTokenItem))
        }
    }

    func dismiss() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
            dismiss(with: nil)
        }
    }
}

// MARK: - Options

extension YieldModulePromoCoordinator {
    struct Options {
        let viewModel: YieldModulePromoViewModel
    }

    typealias DismissOptions = FeeCurrencyNavigatingDismissOption
}
