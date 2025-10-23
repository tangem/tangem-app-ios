//
//  UncompletedBackupViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemSdk
import TangemLocalization
import struct TangemUIUtils.AlertBinder
import struct TangemUIUtils.ConfirmationDialogViewModel

final class UncompletedBackupViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var discardConfirmationDialog: ConfirmationDialogViewModel?
    @Published var error: AlertBinder?

    private weak var coordinator: UncompletedBackupRoutable?

    private lazy var backupHelper = BackupHelper()

    init(
        coordinator: UncompletedBackupRoutable
    ) {
        self.coordinator = coordinator
    }

    func onAppear() {
        showAlert()
    }

    private func showAlert() {
        let alert = Alert(
            title: Text(Localization.commonWarning),
            message: Text(Localization.welcomeInterruptedBackupAlertMessage),
            primaryButton: .default(Text(Localization.welcomeInterruptedBackupAlertResume), action: continueBackup),
            secondaryButton: .destructive(Text(Localization.welcomeInterruptedBackupAlertDiscard), action: showExtraDiscardAlert)
        )

        error = AlertBinder(alert: alert)
    }

    private func showExtraDiscardAlert() {
        let discardButton = ConfirmationDialogViewModel.Button(
            title: Localization.welcomeInterruptedBackupDiscardDiscard,
            role: .destructive,
            action: { [weak self] in
                self?.discardBackup()
            }
        )

        let resumeButton = ConfirmationDialogViewModel.Button(
            title: Localization.welcomeInterruptedBackupDiscardResume,
            role: .cancel,
            action: { [weak self] in
                self?.continueBackup()
            }
        )

        let viewModel = ConfirmationDialogViewModel(
            title: Localization.welcomeInterruptedBackupDiscardTitle,
            subtitle: Localization.welcomeInterruptedBackupDiscardMessage,
            buttons: [
                discardButton,
                resumeButton,
            ]
        )

        DispatchQueue.main.async {
            self.discardConfirmationDialog = viewModel
        }
    }

    private func continueBackup() {
        guard let cardId = backupHelper.cardId else {
            return
        }

        let backupServiceFactory = GenericBackupServiceFactory(isAccessCodeSet: false)

        let factory = ResumeBackupInputFactory(
            cardId: cardId,
            tangemSdkFactory: TangemSdkDefaultFactory(),
            backupServiceFactory: backupServiceFactory
        )
        openBackup(with: factory.makeBackupInput())
    }

    private func discardBackup() {
        Analytics.log(.backupNoticeCanceled)
        backupHelper.discardIncompletedBackup()
        dismiss()
    }
}

// MARK: - Navigation

extension UncompletedBackupViewModel {
    func openBackup(with input: OnboardingInput) {
        coordinator?.openOnboardingModal(with: input)
    }

    func dismiss() {
        coordinator?.dismiss()
    }
}
