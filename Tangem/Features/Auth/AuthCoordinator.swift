//
//  AuthCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class AuthCoordinator: CoordinatorObject {
    typealias OutputOptions = ScanDismissOptions

    // MARK: - Dependencies

    let dismissAction: Action<ScanDismissOptions>
    let popToRootAction: Action<PopToRootOptions>

    @Injected(\.mailComposePresenter) private var mailPresenter: MailComposePresenter
    @Injected(\.safariManager) private var safariManager: SafariManager

    // MARK: - Root view model

    @Published var rootViewModel: AuthViewModel?

    // MARK: - Child coordinators

    @Published var addWalletCoordinator: AddWalletCoordinator?

    required init(
        dismissAction: @escaping Action<ScanDismissOptions>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        rootViewModel = AuthViewModel(unlockOnAppear: options.unlockOnAppear, coordinator: self)
        addWalletCoordinator = makeAddWalletCoordinator()
    }
}

// MARK: - Options

extension AuthCoordinator {
    struct Options {
        let unlockOnAppear: Bool
    }
}

// MARK: - AuthRoutable

extension AuthCoordinator: AuthRoutable {
    func openOnboarding(with input: OnboardingInput) {
        dismiss(with: .onboarding(input))
    }

    func openMain(with userWalletModel: UserWalletModel) {
        dismiss(with: .main(userWalletModel))
    }

    func openAddWallet() {
        addWalletCoordinator?.start(with: .init())
    }

    func openMail(with dataCollector: EmailDataCollector, recipient: String) {
        let logsComposer = LogsComposer(infoProvider: dataCollector)
        let mailViewModel = MailViewModel(logsComposer: logsComposer, recipient: recipient, emailType: .failedToScanCard)

        mailPresenter.present(viewModel: mailViewModel)
    }

    func openScanCardManual() {
        safariManager.openURL(TangemBlogUrlBuilder().url(post: .scanCard))
    }
}

// MARK: - Add wallet

private extension AuthCoordinator {
    func makeAddWalletCoordinator() -> AddWalletCoordinator {
        let dismissAction: Action<AddWalletCoordinator.OutputOptions> = { [weak self] options in
            self?.handleAddWalletDismiss(with: options)
        }

        return AddWalletCoordinator(dismissAction: dismissAction, popToRootAction: popToRootAction)
    }

    func handleAddWalletDismiss(with options: AddWalletCoordinator.OutputOptions) {
        Task { @MainActor [weak self] in
            switch options {
            case .main(let userWalletModel):
                self?.dismiss(with: .main(userWalletModel))
            case .hardwareWallet:
                self?.rootViewModel?.scanCard()
            case .dismiss:
                break
            }
        }
    }
}
