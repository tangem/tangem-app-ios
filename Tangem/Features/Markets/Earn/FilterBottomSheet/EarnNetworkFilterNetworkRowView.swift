//
//  EarnNetworkFilterNetworkRowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct EarnNetworkFilterNetworkRowInput: Identifiable {
    let id: String
    let iconAsset: ImageType
    let networkName: String
    let currencySymbol: String
    let onTap: () -> Void
}

struct EarnNetworkFilterNetworkRowView: View {
    let input: EarnNetworkFilterNetworkRowInput

    var body: some View {
        HStack(spacing: 12) {
            NetworkIcon(
                imageAsset: input.iconAsset,
                isActive: false,
                isMainIndicatorVisible: false,
                size: CGSize(bothDimensions: 24)
            )

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(input.networkName)
                    .lineLimit(1)
                    .layoutPriority(-1)
                    .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                Text(input.currencySymbol)
                    .lineLimit(1)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 16)
        .contentShape(Rectangle())
        .onTapGesture {
            input.onTap()
        }
    }
}
