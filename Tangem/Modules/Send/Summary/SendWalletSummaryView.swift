//
//  SendWalletSummaryView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendWalletSummaryView: View {
    @ObservedObject var viewModel: SendWalletSummaryViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.walletNameTitle(font: UIFonts.Regular.footnote))
                .style(Fonts.Regular.footnote, color: Colors.Text.secondary)

            SensitiveText(viewModel.totalBalance)
                .style(Fonts.Regular.subheadline, color: Colors.Text.tertiary)
        }
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    GroupedScrollView {
        GroupedSection(SendWalletSummaryViewModel(walletName: "Family Wallet", totalBalance: "2 130,88 USDT (2 129,92 $)")) { viewModel in
            SendWalletSummaryView(viewModel: viewModel)
        }
        .backgroundColor(Colors.Button.disabled)
    }
    .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
}
