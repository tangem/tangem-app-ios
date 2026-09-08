//
//  CollectiblesPackCard.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct CollectiblesPackCard: View {
    let model: Model

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.contentSpacing) {
            artwork
            details
        }
    }
}

private extension CollectiblesPackCard {
    // MARK: - View properties

    var artwork: some View {
        artworkContent
            .infinityFrame(axis: .horizontal)
            .frame(height: Metrics.artworkHeight)
            .background(DesignSystem.Color.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Metrics.cornerRadius, style: .continuous)
                    .strokeBorder(DesignSystem.Color.borderPrimary, lineWidth: 1)
            }
    }

    @ViewBuilder
    var artworkContent: some View {
        if let artworkURL = model.artworkURL {
            remoteArtwork(artworkURL)
        } else {
            missingArtworkBadge
        }
    }

    func remoteArtwork(_ url: URL) -> some View {
        CachedAsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                ZStack {
                    // The glow is the artwork itself, blurred: the gray placeholder would read as a dirty halo.
                    glow(image)
                    groundShadow
                    packImage(image)
                        .frame(width: Metrics.packWidth, height: Metrics.packHeight)
                }
            case .empty:
                ZStack {
                    groundShadow
                    loadingPlaceholder
                        .frame(width: Metrics.packWidth, height: Metrics.packHeight)
                }
            case .failure:
                missingArtworkBadge
            @unknown default:
                missingArtworkBadge
            }
        }
    }

    var missingArtworkBadge: some View {
        Circle()
            .fill(DesignSystem.Color.bgOpaquePrimary)
            .frame(size: CGSize(bothDimensions: Metrics.fallbackBadgeSize))
            .overlay {
                DesignSystem.Icons.Error.filled20.image
                    .renderingMode(.template)
                    .resizable()
                    .frame(size: CGSize(bothDimensions: Metrics.fallbackGlyphSize))
                    .foregroundStyle(DesignSystem.Color.iconTertiary)
            }
            .accessibilityHidden(true)
    }

    func glow(_ image: Image) -> some View {
        packImage(image)
            .frame(width: Metrics.packWidth, height: Metrics.packHeight)
            .scaleEffect(Metrics.glowScale)
            .blur(radius: Metrics.glowBlur)
            .opacity(Metrics.glowOpacity)
    }

    var groundShadow: some View {
        Ellipse()
            .fill(.black)
            .frame(width: Metrics.shadowWidth, height: Metrics.shadowHeight)
            .blur(radius: Metrics.shadowBlur)
            .opacity(Metrics.shadowOpacity)
            .offset(y: Metrics.shadowOffset)
    }

    var loadingPlaceholder: some View {
        // Sized to the visible pouch inside the artwork frame (the image carries
        // transparent margins), so the ground shadow peeks out from underneath.
        RoundedRectangle(cornerRadius: Metrics.placeholderCornerRadius, style: .continuous)
            .fill(DesignSystem.Color.bgTertiary)
            .frame(width: Metrics.placeholderWidth, height: Metrics.placeholderHeight)
    }

    func packImage(_ image: Image) -> some View {
        image
            .resizable()
            .aspectRatio(contentMode: .fit)
    }

    var details: some View {
        VStack(alignment: .leading, spacing: Metrics.detailsSpacing) {
            Text(model.title)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)
                .lineLimit(1)

            priceRow
        }
    }

    var priceRow: some View {
        HStack(spacing: Metrics.priceSpacing) {
            Text(model.priceText)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
                .lineLimit(1)

            if let buybackText = model.buybackText {
                Badge(label: buybackText, accessibilityLabel: nil)
                    .size(.x4)
                    .variant(.outline)
            }
        }
    }
}

// MARK: - Metrics

/// Not private: `Skeleton` reads the shared values so the grid does not jump when the content arrives.
extension CollectiblesPackCard {
    enum Metrics {
        static let artworkHeight: CGFloat = 228
        static let packWidth: CGFloat = 144
        static let packHeight: CGFloat = 216
        static let glowScale: CGFloat = 1.12
        static let glowBlur: CGFloat = 18
        static let glowOpacity: CGFloat = 0.55
        static let shadowWidth: CGFloat = 80
        static let shadowHeight: CGFloat = 24
        static let shadowBlur: CGFloat = 10
        static let shadowOpacity: CGFloat = 0.7
        static let shadowOffset: CGFloat = 88
        static let cornerRadius: CGFloat = 20
        static let placeholderCornerRadius: CGFloat = 12
        static let placeholderWidth: CGFloat = 116
        static let placeholderHeight: CGFloat = 169
        static let fallbackBadgeSize: CGFloat = 40
        static let fallbackGlyphSize: CGFloat = 20
        static let contentSpacing: CGFloat = 8
        static let detailsSpacing: CGFloat = 2
        static let priceSpacing: CGFloat = 4
    }
}

// MARK: - Previews

#Preview {
    ZStack {
        DesignSystem.Color.bgPrimary.ignoresSafeArea()

        HStack(alignment: .top, spacing: 12) {
            CollectiblesPackCard(model: .init(
                id: "pokemon-1",
                title: "Legendary 1",
                priceText: "$50",
                buybackText: "Buyback 85%",
                artworkURL: nil
            ))

            CollectiblesPackCard(model: .init(
                id: "sports-2",
                title: "Water 2",
                priceText: "$100",
                buybackText: nil,
                artworkURL: nil
            ))
        }
        .padding(.horizontal, 16)
    }
}
