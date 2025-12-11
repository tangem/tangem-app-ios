//
//  TangemPayFailedToIssueCardSheetViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemLocalization
import TangemUI

struct TangemPayFailedToIssueCardSheetViewModel: FloatingSheetContentViewModel {
    var id: String { String(describing: Self.self) }

    let userWalletModel: UserWalletModel

    let title = Localization.tangempayFailedToIssueCard
    let subtitle = Localization.tangempayFailedToIssueCardSupportDescription

    weak var coordinator: TangemPayFailedToIssueCardRoutable?

    func close() {
        coordinator?.closeFailedToIssueCardSheet()
    }

    var primaryButtonSettings: MainButton.Settings {
        MainButton.Settings(
            title: Localization.tangempayGoToSupport,
            style: .primary,
            size: .default,
            action: goToSupport
        )
    }

    func goToSupport() {
        let dataCollector = TangemPaySupportDataCollector(
            source: .failedToIssueCardSheet,
            userWalletId: userWalletModel.userWalletId.stringValue
        )
        let logsComposer = LogsComposer(infoProvider: dataCollector, includeZipLogs: false)
        let mailViewModel = MailViewModel(
            logsComposer: logsComposer,
            recipient: EmailConfig.visaDefault(subject: .default).recipient,
            emailType: .visaFeedback(subject: .default)
        )

        coordinator?.openMailFromFailedToIssueCardSheet(mailViewModel: mailViewModel)
    }
}
