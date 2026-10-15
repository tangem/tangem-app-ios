//
//  CollectiblesEmptyMessage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct CollectiblesEmptyMessage: View {
    let icon: ImageType
    let message: String
    let onRetry: (() -> Void)?
    var isRetrying = false
    var verticalPadding: CGFloat = Metrics.verticalPadding

    var body: some View {
        VStack(spacing: Metrics.spacing) {
            iconView

            Text(message)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Metrics.horizontalPadding)
        .padding(.vertical, verticalPadding)
        .infinityFrame(axis: .horizontal)
    }
}

private extension CollectiblesEmptyMessage {
    // MARK: - View properties

    @ViewBuilder
    var iconView: some View {
        if let onRetry {
            if isRetrying {
                retryLoader
                    .background(DesignSystem.Color.bgInverse, in: Circle())
            } else {
                SwiftUI.Button(action: onRetry) {
                    glyph(color: DesignSystem.Color.iconInverse)
                        .background(DesignSystem.Color.bgInverse, in: Circle())
                }
                .buttonStyle(.plain)
            }
        } else {
            glyph(color: DesignSystem.Color.iconSecondary)
                .background(DesignSystem.Color.bgTransparentPrimary, in: Circle())
        }
    }

    var retryLoader: some View {
        Loader()
            .loaderSize(.size20)
            .loaderColor(DesignSystem.Color.iconInverse)
            .frame(size: CGSize(bothDimensions: Metrics.containerSize))
    }

    func glyph(color: Color) -> some View {
        icon.image
            .renderingMode(.template)
            .resizable()
            .frame(size: CGSize(bothDimensions: Metrics.iconSize))
            .foregroundStyle(color)
            .frame(size: CGSize(bothDimensions: Metrics.containerSize))
    }
}

// MARK: - Metrics

private extension CollectiblesEmptyMessage {
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
            CollectiblesEmptyMessage(
                icon: DesignSystem.Icons.Stack.regular20,
                message: "There are no packs here yet",
                onRetry: nil
            )

            CollectiblesEmptyMessage(
                icon: DesignSystem.Icons.ArrowRefresh.regular20,
                message: "Failed to load packs.\nTap to reload",
                onRetry: {}
            )
        }
    }
}
