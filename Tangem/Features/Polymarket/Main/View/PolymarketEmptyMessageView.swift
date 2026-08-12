//
//  PolymarketEmptyMessageView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

/// Shown when the feed has nothing to render: the categories failed as a whole, or a single category did.
struct PolymarketEmptyMessageView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: Constants.spacing) {
            SwiftUI.Button(action: onRetry) {
                Assets.reload.image
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: Constants.iconSize, height: Constants.iconSize)
                    .foregroundStyle(DesignSystem.Color.iconInverse)
                    .frame(width: Constants.buttonSize, height: Constants.buttonSize)
                    .background(DesignSystem.Color.bgInverse, in: Circle())
            }
            .buttonStyle(.plain)

            Text(message)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.vertical, Constants.verticalPadding)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Constants

private extension PolymarketEmptyMessageView {
    enum Constants {
        static let spacing: CGFloat = 12
        static let buttonSize: CGFloat = 40
        static let iconSize: CGFloat = 20
        static let horizontalPadding: CGFloat = 64
        static let verticalPadding: CGFloat = 48
    }
}

// MARK: - Previews

#Preview {
    PolymarketEmptyMessageView(message: "Failed to load events.\nTap to reload", onRetry: {})
}
