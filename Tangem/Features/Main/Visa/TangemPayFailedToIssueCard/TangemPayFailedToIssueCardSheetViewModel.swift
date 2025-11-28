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
            title: Localization.commonContactTangemSupport,
            style: .primary,
            size: .default,
            action: goToSupport
        )
    }

    func goToSupport() {
        guard let emailConfig = userWalletModel.emailConfig else {
            return
        }

        let dataCollector = DetailsFeedbackDataCollector(
            data: [
                DetailsFeedbackData(
                    userWalletEmailData: userWalletModel.emailData,
                    walletModels: AccountsFeatureAwareWalletModelsResolver.walletModels(for: userWalletModel)
                ),
            ]
        )

        coordinator?.closeFailedToIssueCardSheet()
        coordinator?.openMail(
            with: dataCollector,
            recipient: emailConfig.recipient,
            emailType: .appFeedback(subject: emailConfig.subject)
        )
    }
}
