//
//  UserWalletBackupStatusHelper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils
import TangemLocalization

struct UserWalletBackupStatusHelper {
    @Injected(\.mailComposePresenter) private var mailComposePresenter: MailComposePresenter
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    /// The alert has no cancel button: `continueAction` goes on with the flow, while `Contact support`
    /// opens mail and runs `cancelAction`, releasing a caller that awaits the outcome.
    func alert(
        for userWalletInfo: UserWalletInfo,
        continueAction: @escaping () -> Void,
        cancelAction: (() -> Void)? = nil
    ) -> AlertBinder? {
        switch userWalletInfo.backupState {
        case .valid:
            return nil
        case .incompleteBackup:
            return makeBackupErrorAlert(userWalletInfo: userWalletInfo, continueAction: continueAction, cancelAction: cancelAction)
        }
    }

    func openBackupErrorSupport(for userWalletInfo: UserWalletInfo) {
        guard let userWalletModel = userWalletRepository.models.first(where: { $0.userWalletId == userWalletInfo.id }) else {
            AppLogger.error(error: "Card-linked wallet \(userWalletInfo.id) is missing from the repository")
            assertionFailure("UserWalletModel not found for a card-linked wallet")
            return
        }

        openBackupErrorSupport(userWalletModel: userWalletModel)
    }

    private func makeBackupErrorAlert(
        userWalletInfo: UserWalletInfo,
        continueAction: @escaping () -> Void,
        cancelAction: (() -> Void)?
    ) -> AlertBinder {
        let alert = Alert(
            title: Text(Localization.warningBackupErrorAddFundsTitleV2),
            message: Text(Localization.warningBackupErrorAddFundsMessageV2),
            primaryButton: .default(Text(Localization.commonContinue)) {
                continueAction()
            },
            secondaryButton: .default(Text(Localization.commonContactSupport)) {
                openBackupErrorSupport(for: userWalletInfo)
                cancelAction?()
            }
        )

        return AlertBinder(alert: alert)
    }

    private func openBackupErrorSupport(userWalletModel: UserWalletModel) {
        Analytics.log(.requestSupport, params: [.source: .main])

        let walletModels = AccountWalletModelsAggregator.walletModels(from: userWalletModel.accountModelsManager)
        let dataCollector = DetailsFeedbackDataCollector(data: [
            .init(userWalletEmailData: userWalletModel.emailData, walletModels: walletModels),
        ])

        let mailViewModel = MailViewModel(
            logsComposer: LogsComposer(infoProvider: dataCollector),
            recipient: EmailConfig.backupError.recipient,
            emailType: .appFeedback(subject: EmailConfig.backupError.subject)
        )

        Task { @MainActor in
            mailComposePresenter.present(viewModel: mailViewModel)
        }
    }
}
