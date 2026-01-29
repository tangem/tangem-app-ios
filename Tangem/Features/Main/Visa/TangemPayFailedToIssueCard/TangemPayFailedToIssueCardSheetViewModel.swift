//
//  TangemPayFailedToIssueCardSheetViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI

final class TangemPayFailedToIssueCardSheetViewModel: TangemPayPopupViewModel {
    var title: AttributedString {
        .init(Localization.tangempayFailedToIssueCard)
    }

    var description: AttributedString {
        .init(Localization.tangempayFailedToIssueCardSupportDescription)
    }

    var primaryButton: MainButton.Settings {
        MainButton.Settings(
            title: Localization.tangempayGoToSupport,
            style: .primary,
            size: .default,
            action: goToSupport
        )
    }

    var icon: Image {
        Assets.Visa.warningCircle.image
    }

    let userWalletModel: UserWalletModel
    weak var coordinator: TangemPayFailedToIssueCardRoutable?

    init(
        userWalletModel: UserWalletModel,
        coordinator: TangemPayFailedToIssueCardRoutable?
    ) {
        self.userWalletModel = userWalletModel
        self.coordinator = coordinator
    }

    func dismiss() {
        coordinator?.closeFailedToIssueCardSheet()
    }

    private func goToSupport() {
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
