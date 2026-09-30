//
//  TransferConfirmationFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemPay

enum TransferConfirmationFactory {
    @MainActor
    static func makeView(
        orderBuilder: TangemPayOfframpOrderBuilder,
        sendUseCase: TangemPayOffRampSendUseCase,
        optionsStore: TangemPayOfframpOptionsStore,
        savedRecipient: TangemPayBankAccountResponse?,
        hasNFCInteraction: Bool,
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
                sendButtonIcon: hasNFCInteraction ? Assets.tangemIcon : nil,
                analyticsLogger: analyticsLogger,
                output: output
            )
        )
    }
}
