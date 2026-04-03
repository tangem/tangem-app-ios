//
//  ActionButtonsSwapCoordinator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemMacro

final class ActionButtonsSwapCoordinator: CoordinatorObject {
    let dismissAction: Action<FeeCurrencyNavigatingDismissOption?>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Injected

    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: FloatingSheetPresenter

    // MARK: - Published

    @Published private(set) var viewType: ViewType?

    // MARK: - Private property

    private let userWalletModel: UserWalletModel
    private let yieldModuleNotificationInteractor: YieldModuleNoticeInteractor

    required init(
        userWalletModel: some UserWalletModel,
        dismissAction: @escaping Action<FeeCurrencyNavigatingDismissOption?>,
        yieldModuleNotificationInteractor: YieldModuleNoticeInteractor,
        popToRootAction: @escaping Action<PopToRootOptions> = { _ in }
    ) {
        self.userWalletModel = userWalletModel
        self.yieldModuleNotificationInteractor = yieldModuleNotificationInteractor
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        let marketsTokensViewModel = SwapMarketsTokensViewModel()

        viewType = .tokenSelector(
            AccountsAwareActionButtonsSwapViewModel(
                tokenSelectorViewModel: options.tokenSelectorViewModel,
                marketsTokensViewModel: marketsTokensViewModel,
                coordinator: self
            )
        )
    }
}

// MARK: - Options

extension ActionButtonsSwapCoordinator {
    struct Options {
        let tokenSelectorViewModel: AccountsAwareTokenSelectorViewModel
    }
}

// MARK: - ActionButtonsSwapRoutable

extension ActionButtonsSwapCoordinator: ActionButtonsSwapRoutable {
    func openSwap(input: PredefinedSwapParameters) {
        let sendCoordinator = SendCoordinator(
            dismissAction: { [weak self] dismissOptions in
                switch dismissOptions {
                case .openFeeCurrency(let feeCurrency):
                    self?.dismissAction(feeCurrency)
                default:
                    self?.dismissAction(.none)
                }
            },
            popToRootAction: popToRootAction
        )

        sendCoordinator.start(with: .init(type: .swap(input), source: .actionButtons))
        viewType = .swap(sendCoordinator)
    }

    func dismiss() {
        ActionButtonsAnalyticsService.trackCloseButtonTap(source: .swap)
        dismiss(with: .none)
    }

    func showYieldNotificationIfNeeded(for walletModel: any WalletModel, completion: (() -> Void)?) {
        guard yieldModuleNotificationInteractor.shouldShowYieldModuleAlert(for: walletModel.tokenItem) else {
            completion.map { $0() }
            return
        }

        Task { @MainActor in
            let vm = YieldNoticeViewModel(tokenItem: walletModel.tokenItem) { [weak self] in
                self?.floatingSheetPresenter.removeActiveSheet()
                completion.map { $0() }
            }

            floatingSheetPresenter.enqueue(sheet: vm)
        }
    }
}

extension ActionButtonsSwapCoordinator {
    @RawCaseName
    enum ViewType: Identifiable {
        case tokenSelector(AccountsAwareActionButtonsSwapViewModel)
        case swap(SendCoordinator)
    }
}
