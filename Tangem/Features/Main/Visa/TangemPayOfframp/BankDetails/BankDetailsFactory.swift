//
//  BankDetailsFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization

enum BankDetailsFactory {
    @MainActor
    static func makeView(
        orderBuilder: TangemPayOfframpOrderBuilder,
        output: @escaping (BankDetailsViewModel.Output) -> Void
    ) -> some View {
        BankDetailsView(
            viewModel: BankDetailsViewModel(
                orderBuilder: orderBuilder,
                title: title(for: orderBuilder.recipient),
                stepSubtitle: TangemPayOfframpWizardStep.bankDetails.subtitle(for: orderBuilder.recipient),
                output: output
            )
        )
    }
}

// MARK: - Title

private extension BankDetailsFactory {
    static func title(for recipient: TangemPayOfframpRecipient) -> String {
        switch recipient {
        case .newBusiness: Localization.tangempayWithdrawHubToBusinessAccount
        case .newIndividual, .saved: Localization.tangempayWithdrawHubToPersonalAccount
        }
    }
}
