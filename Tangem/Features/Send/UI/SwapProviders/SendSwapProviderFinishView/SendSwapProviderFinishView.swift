//
//  SendSwapProviderFinishView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct SendSwapProviderFinishView: View {
    @ObservedObject var viewModel: SendSwapProviderFinishViewModel

    var body: some View {
        HStack(spacing: 12) {
            IconView(
                url: viewModel.providerIcon,
                size: CGSize(width: 36, height: 36),
                forceKingfisher: true
            )

            VStack(alignment: .leading, spacing: 4) {
                titleView

                subtitleView
            }

            Spacer()
        }
        .infinityFrame(axis: .horizontal, alignment: .leading)
        .defaultRoundedBackground(with: Colors.Background.action, verticalPadding: 16, horizontalPadding: 14)
    }

    private var titleView: some View {
        HStack(alignment: .center, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(viewModel.title)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                Text(viewModel.providerType)
                    .style(Fonts.Bold.footnote, color: Colors.Text.primary1)
            }
        }
        .lineLimit(1)
    }

    private var subtitleView: some View {
        Text(viewModel.subtitle)
            .style(Fonts.Regular.body, color: Colors.Text.tertiary)
    }
}
