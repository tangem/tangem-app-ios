//
//  TangemPayMoneyAccountFailedPopupViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

final class TangemPayMoneyAccountFailedPopupViewModel: TangemPayPopupViewModel {
    private let moneyAccount: any TangemPayMoneyAccountModel
    private weak var coordinator: TangemPayMoneyAccountPopupRoutable?

    var title: AttributedString {
        .init(Localization.moneyAccountMainStatusDialogFailedTitle)
    }

    var description: AttributedString {
        .init(Localization.moneyAccountMainStatusDialogFailedDescription)
    }

    var icon: Image {
        DesignSystem.Icons.HeartBroken.regular28.image
    }

    var iconStyle: TangemPayPopupIconStyle {
        .error
    }

    var primaryButton: MainButton.Settings {
        .init(title: Localization.commonContactSupport, style: .primary, action: contactSupport)
    }

    init(moneyAccount: any TangemPayMoneyAccountModel, coordinator: TangemPayMoneyAccountPopupRoutable) {
        self.moneyAccount = moneyAccount
        self.coordinator = coordinator
    }

    func dismiss() {
        coordinator?.closeTangemPayMoneyAccountPopup()
    }

    private func contactSupport() {
        let dataCollector = TangemPayMoneyAccountSupportDataCollector(
            customerId: moneyAccount.customerId,
            accountId: moneyAccount.accountId
        )
        let logsComposer = LogsComposer(infoProvider: dataCollector, includeSystemLogs: false)
        let mailViewModel = MailViewModel(
            logsComposer: logsComposer,
            recipient: EmailConfig.visaDefault(subject: .usdAccountGeneralHelp).recipient,
            emailType: .visaFeedback(subject: .usdAccountGeneralHelp)
        )

        coordinator?.openMailFromTangemPayMoneyAccountPopup(mailViewModel: mailViewModel)
    }
}
