//
//  AccountTypeFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization

enum AccountTypeFactory {
    @MainActor
    static func makeView(
        orderBuilder: TangemPayOfframpOrderBuilder,
        output: @escaping (AccountTypeViewModel.Output) -> Void
    ) -> some View {
        AccountTypeView(
            viewModel: AccountTypeViewModel(
                orderBuilder: orderBuilder,
                title: Localization.tangempayWithdrawBankAccountTypeScreenTitle,
                stepSubtitle: TangemPayOfframpWizardStep.accountType.subtitle(for: orderBuilder.recipient),
                output: output
            )
        )
    }
}
