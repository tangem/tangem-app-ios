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
        Button(action: onTap) {
            HStack(spacing: .unit(.x1)) {
                Assets.search.image
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: Constants.iconSize, height: Constants.iconSize)
                    .foregroundStyle(Color.Tangem.Graphic.Neutral.primary)

                Text(query)
                    .lineLimit(1)
                    .style(.Tangem.Body16.medium, color: .Tangem.Text.Neutral.primary)

                Spacer(minLength: .unit(.x2))

                Assets.DesignSystem.arrowBack.image
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: Constants.iconSize, height: Constants.iconSize)
                    .foregroundStyle(Color.Tangem.Graphic.Neutral.tertiary)
            }
            .padding(.vertical, .unit(.x3))
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

#if DEBUG
#Preview {
    VStack(spacing: 0) {
        MarketsTokenSearchQueryRowView(query: "Usdt", onTap: {})
        MarketsTokenSearchQueryRowView(query: "Eth", onTap: {})
        MarketsTokenSearchQueryRowView(query: "volume > 1M", onTap: {})
    }
    .padding(.horizontal, .unit(.x4))
    .background(Color.Tangem.Surface.level2)
}
#endif // DEBUG
