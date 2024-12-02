//
//  OnrampStatusCompactView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct OnrampStatusCompactView: View {
    @ObservedObject var viewModel: OnrampStatusCompactViewModel

    var body: some View {
        VStack(spacing: 10) {
            statusesView

            DefaultFooterView(Localization.onrampStatusesViewFooter)
                .padding(.horizontal, 14)
        }
    }

    private var statusesView: some View {
        PendingExpressTxStatusView(
            title: Localization.commonTransactionStatus,
            statusesList:
            // Hardcode statuses until it will be refactored
            [
                .init(
                    title: PendingExpressTransactionStatus.awaitingDeposit.activeStatusTitle,
                    state: .loader
                ),
                .init(
                    title: PendingExpressTransactionStatus.confirming.activeStatusTitle,
                    state: .empty
                ),
                .init(
                    title: PendingExpressTransactionStatus.exchanging.activeStatusTitle,
                    state: .empty
                ),
                .init(
                    title: PendingExpressTransactionStatus.sendingToUser.activeStatusTitle,
                    state: .empty
                ),
            ],
            showGoToProviderHeaderButton: false,
            openProviderAction: {}
        )
    }
}
