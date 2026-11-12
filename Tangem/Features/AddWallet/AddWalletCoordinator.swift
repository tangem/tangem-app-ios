//
//  AddWalletCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

final class AddWalletCoordinator: CoordinatorObject {
    let dismissAction: Action<OutputOptions>
    let popToRootAction: Action<PopToRootOptions>

    @Published var sheetViewModel: AddWalletSheetViewModel?
    @Published var onboardingCoordinator: OnboardingCoordinator?
    @Published var socialWalletViewModel: MobileSocialWalletViewModel?

    private var flow: AddWalletFlow?
    private var deferredOutput: DeferredOutput?

    init(
        dismissAction: @escaping Action<OutputOptions>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: InputOptions) {
        deferredOutput = nil

        runTask(in: self) { @MainActor coordinator in
            let flow = AddWalletFlow(delegate: self)
            coordinator.flow = flow
            flow.start()
        }
    }
}

// MARK: - Internal

extension AddWalletCoordinator {
    @MainActor
    func handleSheetDismiss() {
        flow?.handleSheetDismiss()

        switch deferredOutput {
        case .resolved(let options):
            deferredOutput = nil
            dismiss(with: options)
        case .awaiting, .none:
            deferredOutput = nil
        }
    }
}

// MARK: - Options

extension AddWalletCoordinator {
    struct InputOptions {}

    enum OutputOptions {
        case main(userWalletModel: UserWalletModel)
        case hardwareWallet
        case dismiss
    }
}

// MARK: - DeferredOutput

private extension AddWalletCoordinator {
    enum DeferredOutput {
        case awaiting
        case resolved(OutputOptions)
    }
}

// MARK: - AddWalletFlowDelegate

extension AddWalletCoordinator: AddWalletFlowDelegate {
    func present(sheet: AddWalletSheetViewModel) {
        sheetViewModel = sheet
    }

    func dismissSheet() {
        sheetViewModel = nil
        deferredOutput = .awaiting
    }

    func didRequestHardwareWallet() {
        finish(with: .hardwareWallet)
    }

    func didRequestOnboarding(options: OnboardingCoordinator.Options) {
        let dismissAction: Action<OnboardingCoordinator.OutputOptions> = { [weak self] outputOptions in
            switch outputOptions {
            case .main(let userWalletModel):
                self?.dismiss(with: .main(userWalletModel: userWalletModel))
            case .dismiss:
                self?.onboardingCoordinator = nil
                self?.finish(with: .dismiss)
            }
        }

        let coordinator = OnboardingCoordinator(dismissAction: dismissAction)
        coordinator.start(with: options)
        onboardingCoordinator = coordinator
    }

    func didRequestSocialWallet(viewModel: MobileSocialWalletViewModel) {
        socialWalletViewModel = viewModel
    }

    func didCloseSocialWallet() {
        socialWalletViewModel = nil
        finish(with: .dismiss)
    }

    func didAdd(userWalletModel: UserWalletModel) {
        finish(with: .main(userWalletModel: userWalletModel))
    }

    func didFinish() {
        finish(with: .dismiss)
    }
}

// MARK: - Private

private extension AddWalletCoordinator {
    func finish(with options: OutputOptions) {
        if deferredOutput == nil {
            dismiss(with: options)
        } else {
            deferredOutput = .resolved(options)
        }
    }
}
