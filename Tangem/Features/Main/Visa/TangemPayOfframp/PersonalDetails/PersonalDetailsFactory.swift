//
//  PersonalDetailsFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

enum PersonalDetailsFactory {
    @MainActor
    static func makeView(
        orderBuilder: TangemPayOfframpOrderBuilder,
        recentRecipientsStore: TangemPayRecentRecipientsStore,
        output: @escaping (PersonalDetailsViewModel.Output) -> Void
    ) -> some View {
        PersonalDetailsView(
            viewModel: PersonalDetailsViewModel(
                orderBuilder: orderBuilder,
                recentRecipientsStore: recentRecipientsStore,
                title: title(for: orderBuilder.recipient),
                stepSubtitle: TangemPayOfframpWizardStep.personalDetails.subtitle(for: orderBuilder.recipient),
                output: output
            )
        )
    }
}

// MARK: - Title

private extension PersonalDetailsFactory {
    // [REDACTED_TODO_COMMENT]
    static func title(for recipient: TangemPayOfframpRecipient) -> String {
        switch recipient {
        case .newBusiness: "To business account"
        case .newIndividual, .saved: "To personal account"
        }
    }
}
