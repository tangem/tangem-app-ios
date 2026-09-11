//
//  GachaPacksView+Empty.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

extension GachaPacksView {
    struct EmptyMessage: View {
        let icon: ImageType
        let message: String
        let onRetry: (() -> Void)?

        var body: some View {
            VStack(spacing: Metrics.spacing) {
                iconView

                Text(message)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Metrics.horizontalPadding)
            .padding(.vertical, Metrics.verticalPadding)
            .frame(maxWidth: .infinity)
        }
    }
}

private extension GachaPacksView.EmptyMessage {
    // MARK: - View properties

    @ViewBuilder
    var iconView: some View {
        if let onRetry {
            SwiftUI.Button(action: onRetry) {
                glyph(color: DesignSystem.Color.iconInverse)
                    .background(DesignSystem.Color.bgInverse, in: Circle())
            }
            .buttonStyle(.plain)
        } else {
            glyph(color: DesignSystem.Color.iconSecondary)
                .background(DesignSystem.Color.bgOpaquePrimary, in: Circle())
        }
    }

    func glyph(color: Color) -> some View {
        icon.image
            .renderingMode(.template)
            .resizable()
            .frame(width: Metrics.iconSize, height: Metrics.iconSize)
            .foregroundStyle(color)
            .frame(width: Metrics.containerSize, height: Metrics.containerSize)
    }
}

// MARK: - Metrics

private extension GachaPacksView.EmptyMessage {
    enum Metrics {
        static let spacing: CGFloat = 12
        static let containerSize: CGFloat = 40
        static let iconSize: CGFloat = 20
        static let horizontalPadding: CGFloat = 48
        static let verticalPadding: CGFloat = 48
    }
}

// MARK: - Previews

#Preview {
    ZStack {
        DesignSystem.Color.bgPrimary.ignoresSafeArea()

        VStack(spacing: 0) {
            GachaPacksView.EmptyMessage(
                icon: DesignSystem.Icons.Stack.regular20,
                message: "There are no packs here yet",
                onRetry: nil
            )

            GachaPacksView.EmptyMessage(
                icon: DesignSystem.Icons.ArrowRefresh.regular20,
                message: "Failed to load packs.\nTap to reload",
                onRetry: {}
            )
        }
    }
}
