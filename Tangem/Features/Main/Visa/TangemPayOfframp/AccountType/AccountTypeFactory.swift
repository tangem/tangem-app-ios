//
//  AccountTypeFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

enum AccountTypeFactory {
    @MainActor
    static func makeView(
        orderBuilder: TangemPayOfframpOrderBuilder,
        output: @escaping (AccountTypeViewModel.Output) -> Void
    ) -> some View {
        AccountTypeView(
            viewModel: AccountTypeViewModel(
                orderBuilder: orderBuilder,
                title: Constants.title,
                stepSubtitle: TangemPayOfframpWizardStep.accountType.subtitle(for: orderBuilder.recipient),
                output: output
            )
        )
    }
}

// MARK: - Constants

private extension AccountTypeFactory {
    enum Constants {
        // [REDACTED_TODO_COMMENT]
        static let title = "Select account type"
    }
}
