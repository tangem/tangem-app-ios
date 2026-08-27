//
//  TangemPayOfframpCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI

final class TangemPayOfframpCoordinator: CoordinatorObject {
    let dismissAction: Action<DismissOptions?>
    let popToRootAction: Action<PopToRootOptions>

    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter

    // MARK: - Root view model

    @Published private(set) var rootViewModel: WithdrawHubViewModel?

    // MARK: - Child coordinators

    @Published var sendCoordinator: SendCoordinator?

    required init(
        dismissAction: @escaping Action<DismissOptions?>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        rootViewModel = WithdrawHubViewModel(
            withdrawFlowResolver: TangemPayWithdrawFlowResolver(
                fundingFlowBuilder: options.fundingFlowBuilder,
                withdrawAvailabilityProvider: options.tangemPayAccount.withdrawAvailabilityProvider
            ),
            output: { [weak self] in
                self?.handle($0)
            }
        )
    }
}

// MARK: - Coordinator Options

extension TangemPayOfframpCoordinator {
    struct Options {
        let tangemPayAccount: TangemPayAccount
        let fundingFlowBuilder: TangemPayFundingFlowBuilder
    }

    typealias DismissOptions = FeeCurrencyNavigatingDismissOption
}

// MARK: - Withdraw hub output

private extension TangemPayOfframpCoordinator {
    func handle(_ output: WithdrawHubViewModel.Output) {
        switch output {
        case .withdrawNote(let parameters):
            Task { @MainActor in
                let viewModel = TangemPayWithdrawNoteSheetViewModel(
                    parameters: parameters,
                    coordinator: self
                )
                floatingSheetPresenter.enqueue(sheet: viewModel)
            }

        case .withdrawInProgress:
            Task { @MainActor in
                let viewModel = TangemPayWithdrawInProgressSheetViewModel(coordinator: self)
                floatingSheetPresenter.enqueue(sheet: viewModel)
            }

        case .noDepositAddress:
            Task { @MainActor in
                let viewModel = TangemPayNoDepositAddressSheetViewModel(coordinator: self)
                floatingSheetPresenter.enqueue(sheet: viewModel)
            }

        case .close:
            dismiss(with: nil)
        }
    }

    func openSwap(parameters: PredefinedSwapParameters) {
        let dismissAction: Action<SendCoordinator.DismissOptions?> = { [weak self] options in
            self?.sendCoordinator = nil

            switch options {
            case .none, .closeButtonTap, .openSwap:
                break
            case .openFeeCurrency(let feeCurrency):
                self?.dismiss(with: feeCurrency)
            }
        }

        let coordinator = SendCoordinator(
            dismissAction: dismissAction,
            popToRootAction: popToRootAction
        )

        coordinator.start(with: .init(type: .swap(parameters), source: .main))
        sendCoordinator = coordinator
    }
}

// MARK: - TangemPayWithdrawNoteSheetRoutable

extension TangemPayOfframpCoordinator: TangemPayWithdrawNoteSheetRoutable {
    func closeWithdrawNoteSheetPopup() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }

    func openWithdrawal(parameters: PredefinedSwapParameters) {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
            try? await Task.sleep(for: .seconds(0.2))
            openSwap(parameters: parameters)
        }
    }
}

// MARK: - TangemPayWithdrawInProgressSheetRoutable

extension TangemPayOfframpCoordinator: TangemPayWithdrawInProgressSheetRoutable {
    func closeWithdrawInProgressSheet() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }
}

// MARK: - TangemPayNoDepositAddressSheetRoutable

extension TangemPayOfframpCoordinator: TangemPayNoDepositAddressSheetRoutable {
    func closeNoDepositAddressSheet() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }
}
