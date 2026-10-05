//
//  CollectiblesPackCard+Artwork.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import Kingfisher
import TangemAssets
import TangemFoundation
import TangemUI
import TangemUIUtils

extension CollectiblesPackCard {
    struct Artwork: View {
        let url: URL?
        let packSize: CGSize

        @State private var loadingState: LoadingResult<Image, any Error> = .loading

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
        ZStack {
            if case .success(let image) = loadingState {
                glow(image)
            }

            KFImage(url)
                .resizable()
                .cancelOnDisappear(true)
                .fade(duration: Constants.fadeDuration)
                .cacheOriginalImage()
                .onFailureView { missingArtworkBadge }
                .onSuccess { loadingState = .success(Image(uiImage: $0.image)) }
                .onFailure { loadingState = .failure($0) }
                .aspectRatio(contentMode: .fit)
                .frame(width: packSize.width, height: packSize.height)
                .hidden(loadingState.isLoading)
                .overlay { placeholder.hidden(!loadingState.isLoading) }
                .onChange(of: url) { _ in loadingState = .loading }
        }
    }

    var placeholder: some View {
        Shimmer()
            .frame(width: Metrics.placeholderWidth * scale, height: Metrics.placeholderHeight * scale)
            .clipShape(RoundedRectangle(cornerRadius: Metrics.placeholderCornerRadius * scale, style: .continuous))
    }

    var missingArtworkBadge: some View {
        Circle()
            .fill(DesignSystem.Color.bgTransparentPrimary)
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
        image
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: packSize.width, height: packSize.height)
            .scaleEffect(Metrics.glowScale)
            .blur(radius: Metrics.glowBlur * scale)
            .opacity(Metrics.glowOpacity)
            .allowsHitTesting(false)
    }

    // MARK: - Calculations

    var scale: CGFloat {
        packSize.height / Metrics.referencePackHeight
    }
}

// MARK: - Constants

private extension CollectiblesPackCard.Artwork {
    enum Constants {
        static let fadeDuration: TimeInterval = 0.3
    }
}

// MARK: - Metrics

private extension CollectiblesPackCard.Artwork {
    enum Metrics {
        static let referencePackHeight: CGFloat = 216
        static let glowScale: CGFloat = 1.25
        static let glowBlur: CGFloat = 27
        static let glowOpacity: CGFloat = 0.55
        static let placeholderCornerRadius: CGFloat = 12
        static let placeholderWidth: CGFloat = 116
        static let placeholderHeight: CGFloat = 169
        static let fallbackBadgeSize: CGFloat = 40
        static let fallbackGlyphSize: CGFloat = 20
    }
}
