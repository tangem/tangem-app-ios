//
//  MobileUpgradeCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemLocalization
import TangemMobileWalletSdk

final class MobileUpgradeCoordinator: CoordinatorObject {
    @Injected(\.mailComposePresenter) private var mailPresenter: MailComposePresenter

    let dismissAction: Action<OutputOptions>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: MobileUpgradeViewModel?

    // MARK: - Child coordinators

    @Published var onboardingCoordinator: OnboardingCoordinator?

    // MARK: - Helpers

    var onDismissal: () -> Void = {}

    required init(
        dismissAction: @escaping Action<OutputOptions>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }
}

// MARK: - Internal methods

extension MobileUpgradeCoordinator {
    func start(with options: InputOptions) {
        rootViewModel = MobileUpgradeViewModel(
            userWalletModel: options.userWalletModel,
            context: options.context,
            coordinator: self
        )
    }

    func onDismissalAttempt() {
        onboardingCoordinator?.onDismissalAttempt()
    }
}

// MARK: - MobileUpgradeRoutable

extension MobileUpgradeCoordinator: MobileUpgradeRoutable {
    func openOnboarding(input: OnboardingInput) {
        openOnboarding(inputOptions: .input(input))
    }

    func openMail(dataCollector: EmailDataCollector, recipient: String) {
        let logsComposer = LogsComposer(infoProvider: dataCollector)
        let mailViewModel = MailViewModel(logsComposer: logsComposer, recipient: recipient, emailType: .failedToScanCard)

        Task { @MainActor in
            mailPresenter.present(viewModel: mailViewModel)
        }
    }

    func closeMobileUpgrade() {
        dismiss()
    }
}

// MARK: - Navigation

private extension MobileUpgradeCoordinator {
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

    func dismiss() {
        dismiss(with: .dismiss)
    }

    func openMain(userWalletModel: UserWalletModel) {
        dismiss(with: .main(userWalletModel: userWalletModel))
    }
}

// MARK: - Options

extension MobileUpgradeCoordinator {
    struct InputOptions {
        let userWalletModel: UserWalletModel
        let context: MobileWalletContext
    }

    enum OutputOptions {
        case main(userWalletModel: UserWalletModel)
        case dismiss
    }
}
