//
//  HardwareCreateWalletCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemLocalization
import TangemFoundation
import TangemUIUtils
import TangemMobileWalletSdk

final class HardwareCreateWalletCoordinator: CoordinatorObject {
    @Injected(\.mailComposePresenter) private var mailPresenter: MailComposePresenter

    let dismissAction: Action<OutputOptions>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: HardwareCreateWalletViewModel?

    // MARK: - Child coordinators

    @Published var onboardingCoordinator: OnboardingCoordinator?

    required init(
        dismissAction: @escaping Action<OutputOptions>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }
}

// MARK: - Internal methods

extension HardwareCreateWalletCoordinator {
    func start(with options: InputOptions) {
        rootViewModel = HardwareCreateWalletViewModel(
            userWalletModel: options.userWalletModel,
            source: options.source,
            coordinator: self
        )
    }

    func onDismissalAttempt() {
        onboardingCoordinator?.onDismissalAttempt()
    }
}

// MARK: - HardwareCreateWalletRoutable

extension HardwareCreateWalletCoordinator: HardwareCreateWalletRoutable {
    func openOnboarding(input: OnboardingInput) {
        openOnboarding(inputOptions: .input(input))
    }

    func openMain(userWalletModel: UserWalletModel) {
        dismiss(with: .main(userWalletModel: userWalletModel))
    }

    func openMail(dataCollector: EmailDataCollector, recipient: String) {
        let logsComposer = LogsComposer(infoProvider: dataCollector)
        let mailViewModel = MailViewModel(
            logsComposer: logsComposer,
            recipient: recipient,
            emailType: .failedToScanCard
        )

        Task { @MainActor in
            mailPresenter.present(viewModel: mailViewModel)
        }
    }
}

// MARK: - Navigation

private extension HardwareCreateWalletCoordinator {
    func openOnboarding(inputOptions: OnboardingCoordinator.Options) {
        let dismissAction: Action<OnboardingCoordinator.OutputOptions> = { [weak self] options in
            switch options {
            case .main(let userWalletModel):
                self?.openMain(userWalletModel: userWalletModel)
            case .dismiss:
                self?.onboardingCoordinator = nil
            }
        }

        let coordinator = OnboardingCoordinator(dismissAction: dismissAction)
        coordinator.start(with: inputOptions)
        onboardingCoordinator = coordinator
    }
}

// MARK: - Options

extension HardwareCreateWalletCoordinator {
    struct InputOptions {
        let userWalletModel: UserWalletModel?
        let source: HardwareCreateWalletSource
    }

    enum OutputOptions {
        case main(userWalletModel: UserWalletModel)
    }
}
