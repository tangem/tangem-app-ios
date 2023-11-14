//
//  SendWalletSummaryView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendWalletSummaryView: View {
    let viewModel: SendWalletSummaryViewModel

    var body: some View {
        GroupedSection(viewModel) { viewModel in
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.walletNameTitle(fontSize: UIFonts.Regular.caption1.pointSize))
                    .style(Fonts.Regular.caption1, color: Colors.Text.secondary)

                Text(viewModel.totalBalance)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
            }
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .backgroundColor(Colors.Button.disabled)
    }
}

#Preview {
    GroupedScrollView {
        SendWalletSummaryView(viewModel: SendWalletSummaryViewModel(walletName: "Family Wallet", totalBalance: "2 130,88 USDT (2 129,92 $)"))
    }
    .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
}
