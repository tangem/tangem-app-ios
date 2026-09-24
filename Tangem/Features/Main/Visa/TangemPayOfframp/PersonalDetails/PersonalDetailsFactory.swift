//
//  PersonalDetailsFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization

enum PersonalDetailsFactory {
    @MainActor
    static func makeView(
        orderBuilder: TangemPayOfframpOrderBuilder,
        recentRecipientsStore: TangemPayRecentRecipientsStore,
        analyticsLogger: any TangemPayOfframpAnalyticsLogger,
        output: @escaping (PersonalDetailsViewModel.Output) -> Void
    ) -> some View {
        PersonalDetailsView(
            viewModel: PersonalDetailsViewModel(
                orderBuilder: orderBuilder,
                recentRecipientsStore: recentRecipientsStore,
                title: title(for: orderBuilder.recipient),
                stepSubtitle: TangemPayOfframpWizardStep.personalDetails.subtitle(for: orderBuilder.recipient),
                analyticsLogger: analyticsLogger,
                output: output
            )
        )
    }
}

// MARK: - Title

private extension PersonalDetailsFactory {
    static func title(for recipient: TangemPayOfframpRecipient) -> String {
        switch recipient {
        case .newBusiness: Localization.tangempayWithdrawHubToBusinessAccount
        case .newIndividual, .saved: Localization.tangempayWithdrawHubToPersonalAccount
        }
    }
}
