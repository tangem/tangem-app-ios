//
//  AuthCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class AuthCoordinator: CoordinatorObject {
    typealias OutputOptions = ScanDismissOptions

    // MARK: - Dependencies

    let dismissAction: Action<ScanDismissOptions>
    let popToRootAction: Action<PopToRootOptions>

    @Injected(\.safariManager) private var safariManager: SafariManager

    // MARK: - Root view model

    @Published var rootViewModel: AuthViewModel?
    @Published var newRootViewModel: NewAuthViewModel?

    // MARK: - Child coordinators

    @Published var addWalletSelectorCoordinator: AddWalletSelectorCoordinator?

    // MARK: - Child view models

    @Published var mailViewModel: MailViewModel?

    required init(
        dismissAction: @escaping Action<ScanDismissOptions>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        // [REDACTED_TODO_COMMENT]
        if FeatureProvider.isAvailable(.mobileWallet) {
            newRootViewModel = NewAuthViewModel(unlockOnAppear: options.unlockOnAppear, coordinator: self)
        } else {
            rootViewModel = AuthViewModel(unlockOnAppear: options.unlockOnAppear, coordinator: self)
        }
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

    func openMail(with dataCollector: EmailDataCollector, recipient: String) {
        let logsComposer = LogsComposer(infoProvider: dataCollector)
        mailViewModel = MailViewModel(logsComposer: logsComposer, recipient: recipient, emailType: .failedToScanCard)
    }

    func openScanCardManual() {
        safariManager.openURL(TangemBlogUrlBuilder().url(post: .scanCard))
    }
}

// MARK: - NewAuthRoutable

extension AuthCoordinator: NewAuthRoutable {
    func openAddWallet() {
        let dismissAction: Action<AddWalletSelectorCoordinator.OutputOptions> = { [weak self] options in
            switch options {
            case .main(let userWallet):
                self?.dismiss(with: .main(userWallet))
            }
        }

        let coordinator = AddWalletSelectorCoordinator(dismissAction: dismissAction)
        let inputOptions = AddWalletSelectorCoordinator.InputOptions()
        coordinator.start(with: inputOptions)
        addWalletSelectorCoordinator = coordinator
    }
}
