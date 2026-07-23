//
//  MarketsTokenSearchQueryRowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct MarketsTokenSearchQueryRowView: View {
    let query: String
    let onTap: () -> Void

    var body: some View {
        SwiftUI.Button(action: onTap) {
            HStack(spacing: 4) {
                Assets.search.image
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: Constants.iconSize, height: Constants.iconSize)
                    .foregroundStyle(DesignSystem.Color.iconPrimary)

                Text(query)
                    .lineLimit(1)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

                Spacer(minLength: 8)

                Assets.DesignSystem.arrowBack.image
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: Constants.iconSize, height: Constants.iconSize)
                    .foregroundStyle(DesignSystem.Color.iconSecondary)
            }
            .padding(.vertical, 20)
        }
    }
}

// MARK: - Constants

private extension MarketsTokenSearchQueryRowView {
    enum Constants {
        static let iconSize: CGFloat = 24
    }
}

// MARK: - Previews

#Preview {
    VStack(spacing: 0) {
        MarketsTokenSearchQueryRowView(query: "Usdt", onTap: {})
        MarketsTokenSearchQueryRowView(query: "Eth", onTap: {})
        MarketsTokenSearchQueryRowView(query: "volume > 1M", onTap: {})
    }
    .padding(.horizontal, 16)
    .background(DesignSystem.Color.bgPrimary)
}
