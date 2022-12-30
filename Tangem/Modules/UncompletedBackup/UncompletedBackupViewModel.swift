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
        let alert = Alert(title: Text("common_warning"),
                          message: Text("welcome_interrupted_backup_alert_message"),
                          primaryButton: .default(Text("welcome_interrupted_backup_alert_resume"), action: continueBackup),
                          secondaryButton: .destructive(Text("welcome_interrupted_backup_alert_discard"), action: showExtraDiscardAlert))

        self.error = AlertBinder(alert: alert)
    }

    private func showExtraDiscardAlert() {
        let buttonResume: ActionSheet.Button = .cancel(Text("welcome_interrupted_backup_discard_resume"), action: continueBackup)
        let buttonDiscard: ActionSheet.Button = .destructive(Text("welcome_interrupted_backup_discard_discard"), action: discardBackup)
        let sheet = ActionSheet(title: Text("welcome_interrupted_backup_discard_title"),
                                message: Text("welcome_interrupted_backup_discard_message"),
                                buttons: [buttonDiscard, buttonResume])

        DispatchQueue.main.async {
            self.discardAlert = ActionSheetBinder(sheet: sheet)
        }
    }

    private func continueBackup() {
        guard let primaryCardId = backupService.primaryCard?.cardId else {
            return
        }

        let input = OnboardingInput(steps: .wallet(WalletOnboardingStep.resumeBackupSteps),
                                    cardInput: .cardId(primaryCardId),
                                    welcomeStep: nil,
                                    twinData: nil,
                                    currentStepIndex: 0,
                                    isStandalone: true)

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
