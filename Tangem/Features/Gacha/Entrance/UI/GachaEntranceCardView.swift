//
//  GachaEntranceCardView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct GachaEntranceCardView: View {
    @StateObject private var viewModel: GachaEntranceViewModel

    private let onOpenRequested: @MainActor (GachaCoordinator.Options) -> Void

    @ScaledMetric private var cardWidth: CGFloat = 180
    @ScaledMetric private var cardHeight: CGFloat = 212

    @ScaledMetric private var starSize: CGFloat = 20
    @ScaledMetric private var chipSize: CGFloat = 40

    @ScaledMetric private var plusIconSize: CGFloat = 16
    @ScaledMetric private var plusBadgeSize: CGFloat = 24

    init(
        userWalletModelsProvider: @autoclosure @escaping () -> [UserWalletModel],
        onOpenRequested: @MainActor @escaping (GachaCoordinator.Options) -> Void
    ) {
        self.onOpenRequested = onOpenRequested
        _viewModel = StateObject(wrappedValue: GachaEntranceViewModel(userWalletModelsProvider: userWalletModelsProvider))
    }

    var body: some View {
        SwiftUI.Button(action: { viewModel.openGacha(onOpen: onOpenRequested) }) {
            content
        }
        .buttonStyle(.plain)
    }
}

private extension GachaEntranceCardView {
    // MARK: - View properties

    var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                starChip

                Spacer()

                plusBadge
            }

            Spacer()

            titleAndDescription
        }
        .padding(Metrics.contentPadding)
        .frame(width: cardWidth, height: cardHeight)
        .background(background)
    }

    var starChip: some View {
        Assets.Accounts.starAccounts.image
            .renderingMode(.template)
            .resizable()
            .foregroundStyle(Color.white)
            .frame(size: CGSize(bothDimensions: starSize))
            .frame(size: CGSize(bothDimensions: chipSize))
            .background(DesignSystem.Color.bgStatusWarning)
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(DesignSystem.Color.borderSecondary, lineWidth: Metrics.chipBorderWidth))
    }

    var plusBadge: some View {
        DesignSystem.Icons.SignPlus.regular16.image
            .renderingMode(.template)
            .resizable()
            .frame(size: CGSize(bothDimensions: plusIconSize))
            .foregroundStyle(DesignSystem.Color.iconInverse)
            .frame(size: CGSize(bothDimensions: plusBadgeSize))
            .background(DesignSystem.Color.bgInverse)
            .clipShape(Circle())
    }

    var titleAndDescription: some View {
        VStack(alignment: .leading, spacing: Metrics.textSpacing) {
            // [REDACTED_TODO_COMMENT]
            Text("Explore collections").style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)

            // [REDACTED_TODO_COMMENT]
            Text("Open packs of graded collectible cards")
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)
        }
    }

    var background: some View {
        RoundedRectangle(cornerRadius: Metrics.cornerRadius, style: .continuous)
            .fill(DesignSystem.Color.bgOpaquePrimary)
            .overlay(glow)
            .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Metrics.cornerRadius, style: .continuous)
                    .strokeBorder(DesignSystem.Color.borderSecondary, lineWidth: Metrics.cardBorderWidth)
            )
    }

    var glow: some View {
        ZStack {
            Circle()
                .fill(.black)
                .frame(size: CGSize(bothDimensions: Metrics.vignetteSize))
                .blur(radius: Metrics.vignetteBlur)

            Circle()
                .fill(DesignSystem.Color.iconStatusWarning)
                .frame(size: CGSize(bothDimensions: Metrics.glowSize))
                .blur(radius: Metrics.glowBlur)
        }
        .offset(y: Metrics.glowCenterOffsetY)
    }
}

// MARK: - Metrics

private extension GachaEntranceCardView {
    enum Metrics {
        static let cornerRadius: CGFloat = 24
        static let cardBorderWidth: CGFloat = 0.5
        static let contentPadding: CGFloat = 16

        static let chipBorderWidth: CGFloat = 0.75
        static let textSpacing: CGFloat = 4

        static let vignetteSize: CGFloat = 240
        static let vignetteBlur: CGFloat = 40
        static let glowSize: CGFloat = 117.5
        static let glowBlur: CGFloat = 52.5
        static let glowCenterOffsetY: CGFloat = 94
    }
}

// MARK: - Previews

#Preview {
    ZStack {
        DesignSystem.Color.bgPrimary.ignoresSafeArea()

        GachaEntranceCardView(userWalletModelsProvider: [], onOpenRequested: { _ in })
    }
}
