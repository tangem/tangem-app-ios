//
//  TransferConfirmationFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemPay
import TangemUI

enum TransferConfirmationFactory {
    @MainActor
    static func makeView(
        orderBuilder: TangemPayOfframpOrderBuilder,
        sendUseCase: TangemPayOffRampSendUseCase,
        optionsStore: TangemPayOfframpOptionsStore,
        savedRecipient: TangemPayBankAccountResponse?,
        signingActionButtonType: SigningActionButtonViewType,
        analyticsLogger: any TangemPayOfframpAnalyticsLogger,
        output: @escaping (TransferConfirmationViewModel.Output) -> Void
    ) -> some View {
        TransferConfirmationView(
            viewModel: TransferConfirmationViewModel(
                orderBuilder: orderBuilder,
                sendUseCase: sendUseCase,
                options: optionsStore.state.options ?? .empty,
                savedRecipient: savedRecipient,
                title: Localization.tangempayWithdrawBankConfirmTitle,
                signingActionButtonType: signingActionButtonType,
                analyticsLogger: analyticsLogger,
                output: output
            )
        )
    }
}
