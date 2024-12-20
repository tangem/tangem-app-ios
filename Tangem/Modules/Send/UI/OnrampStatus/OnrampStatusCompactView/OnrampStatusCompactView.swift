//
//  OnrampStatusCompactView.swift
//  TangemApp
//
//  Created by Sergey Balashov on 28.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

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
            showGoToProviderHeaderButton: false,
            openProviderAction: {}
        )
    }
}
