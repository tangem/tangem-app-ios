//
//  UncompletedBackupViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemSdk

final class UncompletedBackupViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var discardAlert: ActionSheetBinder?
    @Published var error: AlertBinder?

    // MARK: - Dependencies

    @Injected(\.backupServiceProvider) private var backupServiceProvider: BackupServiceProviding

    private unowned let coordinator: UncompletedBackupRoutable
    private var backupService: BackupService { backupServiceProvider.backupService }

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
        let buttonResume: ActionSheet.Button = .cancel(Text(Localization.welcomeInterruptedBackupDiscardResume), action: continueBackup)
        let buttonDiscard: ActionSheet.Button = .destructive(Text(Localization.welcomeInterruptedBackupDiscardDiscard), action: discardBackup)
        let sheet = ActionSheet(
            title: Text(Localization.welcomeInterruptedBackupDiscardTitle),
            message: Text(Localization.welcomeInterruptedBackupDiscardMessage),
            buttons: [buttonDiscard, buttonResume]
        )

        DispatchQueue.main.async {
            self.discardAlert = ActionSheetBinder(sheet: sheet)
        }
    }

    private func continueBackup() {
        guard let primaryCardId = backupService.primaryCard?.cardId else {
            return
        }

        let input = OnboardingInput(
            steps: .wallet(WalletOnboardingStep.resumeBackupSteps),
            cardInput: .cardId(primaryCardId),
            twinData: nil,
            currentStepIndex: 0,
            isStandalone: true
        )

        openBackup(with: input)
    }

    private func discardBackup() {
        backupService.discardIncompletedBackup()
        dismiss()
    }
}

// MARK: - Navigation

extension UncompletedBackupViewModel {
    func openBackup(with input: OnboardingInput) {
        coordinator.openOnboardingModal(with: input)
    }

    func dismiss() {
        coordinator.dismiss()
    }
}
