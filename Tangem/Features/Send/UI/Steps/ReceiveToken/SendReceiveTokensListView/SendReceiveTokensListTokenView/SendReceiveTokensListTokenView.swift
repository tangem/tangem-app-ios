//
//  SendReceiveTokensListTokenView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemAccessibilityIdentifiers

struct SendReceiveTokensListTokenView: View {
    let viewModel: SendReceiveTokensListTokenViewData

    var body: some View {
        SwiftUI.Button(action: viewModel.tapAction) {
            HStack(alignment: .center, spacing: 12) {
                IconView(url: viewModel.iconURL, size: CGSize(width: 36, height: 36), forceKingfisher: true)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(viewModel.name)
                        .style(Fonts.Bold.subheadline, color: DesignSystem.Color.textPrimary)

                    Text(viewModel.symbol)
                        .style(Fonts.Regular.caption1, color: DesignSystem.Color.textSecondary)
                }

                Spacer()
            }
            .multilineTextAlignment(.leading)
        }
        .accessibilityIdentifier(SendAccessibilityIdentifiers.receiveTokenListItem(name: viewModel.name))
    }
}
