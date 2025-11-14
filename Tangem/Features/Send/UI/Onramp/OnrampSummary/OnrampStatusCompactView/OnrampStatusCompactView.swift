//
//  OnrampStatusCompactView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization

struct OnrampStatusCompactView: View {
    @ObservedObject var viewModel: OnrampStatusCompactViewModel

    var body: some View {
        VStack(spacing: 10) {
            statusesView

            DefaultFooterView(Localization.onrampTransactionStatusFooterText)
                .padding(.horizontal, 14)
        }
    }

    private var statusesView: some View {
        PendingExpressTxStatusView(
            title: Localization.commonTransactionStatus,
            statusesList: viewModel.statusesList,
            topTrailingAction: viewModel.externalTxId.map { .copyTxId(id: $0) }
        )
    }
}
