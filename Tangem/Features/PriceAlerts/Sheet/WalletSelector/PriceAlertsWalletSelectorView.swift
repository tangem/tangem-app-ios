//
//  PriceAlertsWalletSelectorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

// Skeleton: the wallet list, "Don't ask again" and "Add to price alert" are [REDACTED_INFO].
struct PriceAlertsWalletSelectorView: View {
    @ObservedObject var viewModel: PriceAlertsWalletSelectorViewModel

    var body: some View {
        VStack(spacing: 16) {
            // [REDACTED_TODO_COMMENT]
            Text("Choose wallet")
                .style(Fonts.Bold.title3, color: Colors.Text.primary1)

            Button(action: viewModel.closeAction) {
                Text("Close")
            }
        }
        .padding(16)
    }
}
