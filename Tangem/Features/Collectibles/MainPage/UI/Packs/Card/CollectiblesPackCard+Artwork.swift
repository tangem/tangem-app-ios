//
//  CollectiblesPackCard+Artwork.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

extension CollectiblesPackCard {
    struct Artwork: View {
        let url: URL?
        let packSize: CGSize

        var body: some View {
            if let url {
                remoteArtwork(url)
            } else {
                missingArtworkBadge
            }
        }
    }
}

private extension CollectiblesPackCard.Artwork {
    // MARK: - View properties

    func remoteArtwork(_ url: URL) -> some View {
        CachedAsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                ZStack {
                    // The glow is the artwork itself, blurred: the gray placeholder would read as a dirty halo.
                    glow(image)
                    groundShadow
                    packImage(image)
                        .frame(width: packSize.width, height: packSize.height)
                }
            case .empty:
                ZStack {
                    groundShadow
                    loadingPlaceholder
                        .frame(width: packSize.width, height: packSize.height)
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
            .frame(size: CGSize(bothDimensions: Metrics.fallbackBadgeSize * scale))
            .overlay {
                DesignSystem.Icons.Error.filled20.image
                    .renderingMode(.template)
                    .resizable()
                    .frame(size: CGSize(bothDimensions: Metrics.fallbackGlyphSize * scale))
                    .foregroundStyle(DesignSystem.Color.iconTertiary)
            }
            .accessibilityHidden(true)
    }

    func glow(_ image: Image) -> some View {
        packImage(image)
            .frame(width: packSize.width, height: packSize.height)
            .scaleEffect(Metrics.glowScale)
            .blur(radius: Metrics.glowBlur * scale)
            .opacity(Metrics.glowOpacity)
    }

    var groundShadow: some View {
        Ellipse()
            .fill(.black)
            .frame(width: Metrics.shadowWidth * scale, height: Metrics.shadowHeight * scale)
            .blur(radius: Metrics.shadowBlur * scale)
            .opacity(Metrics.shadowOpacity)
            .offset(y: Metrics.shadowOffset * scale)
    }

    var loadingPlaceholder: some View {
        // Sized to the visible pouch inside the artwork frame (the image carries
        // transparent margins), so the ground shadow peeks out from underneath.
        RoundedRectangle(cornerRadius: Metrics.placeholderCornerRadius * scale, style: .continuous)
            .fill(DesignSystem.Color.bgTertiary)
            .frame(width: Metrics.placeholderWidth * scale, height: Metrics.placeholderHeight * scale)
    }

    func packImage(_ image: Image) -> some View {
        image
            .resizable()
            .aspectRatio(contentMode: .fit)
    }

    // MARK: - Calculations

    var scale: CGFloat {
        packSize.height / Metrics.referencePackHeight
    }
}

// MARK: - Metrics

private extension CollectiblesPackCard.Artwork {
    /// Values are taken at the grid card's pack size and scale linearly from it.
    enum Metrics {
        static let referencePackHeight: CGFloat = 216
        static let glowScale: CGFloat = 1.12
        static let glowBlur: CGFloat = 18
        static let glowOpacity: CGFloat = 0.55
        static let shadowWidth: CGFloat = 80
        static let shadowHeight: CGFloat = 24
        static let shadowBlur: CGFloat = 10
        static let shadowOpacity: CGFloat = 0.7
        static let shadowOffset: CGFloat = 88
        static let placeholderCornerRadius: CGFloat = 12
        static let placeholderWidth: CGFloat = 116
        static let placeholderHeight: CGFloat = 169
        static let fallbackBadgeSize: CGFloat = 40
        static let fallbackGlyphSize: CGFloat = 20
    }
}
