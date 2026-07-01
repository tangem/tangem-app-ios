//
//  PriceAlertsWalletSelectorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct PriceAlertsWalletSelectorView: View {
    @ObservedObject var viewModel: PriceAlertsWalletSelectorViewModel

    var body: some View {
        VStack(spacing: 16) {
            // [REDACTED_TODO_COMMENT]
            Text("Choose wallet")
                .style(Fonts.Bold.title3, color: Colors.Text.primary1)
                .frame(maxWidth: .infinity, alignment: .center)

            VStack(spacing: 0) {
                ForEach(viewModel.walletItems) { itemViewModel in
                    WalletSelectorItemView(viewModel: itemViewModel)
                }
            }

            dontAskAgainRow

            MainButton(
                title: "Add to price alert",
                isDisabled: !viewModel.isAddEnabled,
                action: viewModel.addToPriceAlertTapped
            )
        }
        .padding(16)
        .alert(item: $viewModel.alert) { $0.alert }
    }

    private var dontAskAgainRow: some View {
        Button(action: { viewModel.isDontAskAgainEnabled.toggle() }) {
            HStack(spacing: 8) {
                Image(systemName: viewModel.isDontAskAgainEnabled ? "checkmark.square.fill" : "square")
                    .foregroundStyle(viewModel.isDontAskAgainEnabled ? Colors.Icon.accent : Colors.Icon.informative)

                Text("Don't ask again")
                    .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)

                Spacer()
            }
            .contentShape(.rect)
        }
    }
}
