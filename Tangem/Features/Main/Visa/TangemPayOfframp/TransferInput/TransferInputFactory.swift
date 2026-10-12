//
//  TransferInputFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemLocalization
import TangemPay

enum TransferInputFactory {
    @MainActor
    static func makeViewModel(
        orderBuilder: TangemPayOfframpOrderBuilder,
        optionsStore: TangemPayOfframpOptionsStore,
        recipient: TangemPayOfframpRecipient,
        savedRecipientName: String?,
        analyticsLogger: any TangemPayOfframpAnalyticsLogger,
        output: @escaping (TransferInputViewModel.Output) -> Void
    ) -> TransferInputViewModel {
        TransferInputViewModel(
            orderBuilder: orderBuilder,
            optionsStore: optionsStore,
            title: title(recipient: recipient, savedRecipientName: savedRecipientName),
            stepSubtitle: TangemPayOfframpWizardStep.amount.subtitle(for: recipient),
            analyticsLogger: analyticsLogger,
            output: output
        )
    }
}

// MARK: - Header

private extension TransferInputFactory {
    static func title(recipient: TangemPayOfframpRecipient, savedRecipientName: String?) -> String {
        switch recipient {
        case .saved:
            savedRecipientName ?? Localization.tangempayWithdrawHubBankSectionTitle
        case .newIndividual:
            Localization.tangempayWithdrawHubToPersonalAccount
        case .newBusiness:
            Localization.tangempayWithdrawHubToBusinessAccount
        }
    }
}
