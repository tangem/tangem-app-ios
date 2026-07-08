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

    func alert(for userWalletInfo: UserWalletInfo) -> AlertBinder? {
        switch userWalletInfo.backupState {
        case .valid:
            return nil
        case .incompleteBackup:
            return makeBackupErrorAlert(userWalletInfo: userWalletInfo)
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

    private func makeBackupErrorAlert(userWalletInfo: UserWalletInfo) -> AlertBinder? {
        guard let userWalletModel = userWalletRepository.models.first(where: { $0.userWalletId == userWalletInfo.id }) else {
            AppLogger.error(error: "Card-linked wallet \(userWalletInfo.id) is missing from the repository")
            assertionFailure("UserWalletModel not found for a card-linked wallet")
            return nil
        }

        let alert = Alert(
            title: Text(Localization.warningBackupErrorAddFundsTitle),
            message: Text(Localization.warningBackupErrorAddFundsMessage),
            primaryButton: .default(Text(Localization.commonContactSupport)) {
                openBackupErrorSupport(userWalletModel: userWalletModel)
            },
            secondaryButton: .cancel()
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
