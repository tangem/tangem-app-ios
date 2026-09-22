//
//  TransferTypeFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization

enum TransferTypeFactory {
    @MainActor
    static func makeView(
        orderBuilder: TangemPayOfframpOrderBuilder,
        output: @escaping (TransferTypeViewModel.Output) -> Void
    ) -> some View {
        TransferTypeView(
            viewModel: TransferTypeViewModel(
                orderBuilder: orderBuilder,
                title: Localization.tangempayWithdrawHubToPersonalAccount,
                stepSubtitle: TangemPayOfframpWizardStep.transferType.subtitle(for: orderBuilder.recipient),
                output: output
            )
        )
    }
}
