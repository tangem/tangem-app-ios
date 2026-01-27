//
//  EarnFilterHeaderView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct EarnFilterHeaderView: View {
    var body: some View {
        HStack(spacing: Layout.filterSpacing) {
            filterButton(title: "All networks")
            filterButton(title: "All types")
            Spacer()
        }
        .padding(.horizontal, Layout.horizontalPadding)
        .padding(.vertical, Layout.verticalPadding)
    }

    private func filterButton(title: String) -> some View {
        Button {
            // Placeholder - will be implemented in future iteration
        } label: {
            HStack(spacing: 6) {
                Text(title)
                    .style(Fonts.Bold.footnote, color: Colors.Text.primary1)

                Assets.chevronDownMini.image
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Colors.Button.secondary)
            )
        }
    }
}

private extension EarnFilterHeaderView {
    enum Layout {
        static let filterSpacing: CGFloat = 8.0
        static let horizontalPadding: CGFloat = 16.0
        static let verticalPadding: CGFloat = 8.0
    }
}
