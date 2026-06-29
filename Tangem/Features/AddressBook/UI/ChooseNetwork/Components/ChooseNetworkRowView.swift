//
//  ChooseNetworkRowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import BlockchainSdk

struct ChooseNetworkRowView: View {
    let viewModel: ChooseNetworkRowViewModel

    var body: some View {
        TangemRow(title: viewModel.blockchain.displayName)
            .verticalAlignment(.center)
            .titleLineLimit(1)
            .titleAccessory {
                Text(viewModel.blockchain.currencySymbol)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textSecondary)
                    .lineLimit(1)
                    .layoutPriority(-1)
            }
            .start {
                NetworkIcon(
                    imageAsset: NetworkImageProvider().provide(by: viewModel.blockchain, filled: true),
                    isActive: false,
                    isMainIndicatorVisible: false,
                    size: CGSize(bothDimensions: 36)
                )
            }
            .end {
                selectionIcon
            }
            .onTap(viewModel.onTap)
    }

    @ViewBuilder
    private var selectionIcon: some View {
        Group {
            if viewModel.isSelected {
                ZStack {
                    DesignSystem.Icons.ControlCircle.filled24.image
                        .renderingMode(.template)
                        .foregroundStyle(DesignSystem.Color.iconPrimary)

                    DesignSystem.Icons.ControlCheckmark.regular24.image
                        .renderingMode(.template)
                        .foregroundStyle(DesignSystem.Color.bgPrimary)
                }
            } else {
                DesignSystem.Icons.ControlCircle.regular24.image
                    .renderingMode(.template)
                    .foregroundStyle(DesignSystem.Color.iconTertiary)
            }
        }
        .frame(width: 24, height: 24)
    }
}
