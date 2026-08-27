//
//  WithdrawHubContentView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct WithdrawHubContentView: View {
    let isWithinPortfolioLoading: Bool
    let onWithinPortfolioTap: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            swapSection

            // [REDACTED_TODO_COMMENT]

            Spacer()
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Subviews

private extension WithdrawHubContentView {
    var swapSection: some View {
        WithdrawHubSectionView(
            // [REDACTED_TODO_COMMENT]
            title: "Transfer or swap",
            // [REDACTED_TODO_COMMENT]
            subtitle: "From your payment account",
            staticContent: {
                WithdrawHubActionTileView(
                    icon: DesignSystem.Icons.ArrowSwapHorizontal.regular20,
                    // [REDACTED_TODO_COMMENT]
                    title: "Within your portfolio",
                    action: onWithinPortfolioTap
                )
                .disabled(isWithinPortfolioLoading)
            },
            dynamicContent: {
                // [REDACTED_TODO_COMMENT]
                EmptyView()
            }
        )
    }
}

// MARK: - Previews

#Preview {
    WithdrawHubContentView(
        isWithinPortfolioLoading: false,
        onWithinPortfolioTap: {}
    )
}
