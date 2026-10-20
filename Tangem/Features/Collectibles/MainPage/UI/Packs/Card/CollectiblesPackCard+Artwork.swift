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
        var hasFailureCard = false
        var glow: Glow = .card

        @State private var loadingState: LoadingResult<Image, any Error> = .loading

        var body: some View {
            GeometryReader { proxy in
                content(packSize: proxy.size)
                    .frame(width: proxy.size.width, height: proxy.size.height)
            }
        }
    }
}

private extension CollectiblesPackCard.Artwork {
    // MARK: - View properties

    @ViewBuilder
    func content(packSize: CGSize) -> some View {
        if let url {
            remoteArtwork(url, packSize: packSize)
        } else {
            failureView(packSize: packSize)
        }
    }

    func remoteArtwork(_ url: URL, packSize: CGSize) -> some View {
        ZStack {
            if case .success(let image) = loadingState {
                glow(image, packSize: packSize)
            }

            KFImage(url)
                .resizable()
                .cancelOnDisappear(true)
                .fade(duration: Constants.fadeDuration)
                .cacheOriginalImage()
                .onFailureView { failureView(packSize: packSize) }
                .onSuccess { loadingState = .success(Image(uiImage: $0.image)) }
                .onFailure { loadingState = .failure($0) }
                .aspectRatio(contentMode: .fit)
                .frame(width: packSize.width, height: packSize.height)
                .hidden(loadingState.isLoading)
                .overlay { placeholder(packSize: packSize).hidden(!loadingState.isLoading) }
                .onChange(of: url) { _ in loadingState = .loading }
        }
    }

    func placeholder(packSize: CGSize) -> some View {
        let scale = scale(for: packSize)

        return Shimmer()
            .aspectRatio(Metrics.artworkAspectRatio, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: Metrics.placeholderCornerRadius * scale, style: .continuous))
            .frame(width: packSize.width, height: packSize.height)
    }

    @ViewBuilder
    func failureView(packSize: CGSize) -> some View {
        let scale = scale(for: packSize)

        if hasFailureCard {
            missingArtworkBadge
                .infinityFrame()
                .aspectRatio(Metrics.artworkAspectRatio, contentMode: .fit)
                .background(
                    DesignSystem.Color.bgSecondary,
                    in: RoundedRectangle(cornerRadius: Metrics.placeholderCornerRadius * scale, style: .continuous)
                )
                .frame(width: packSize.width, height: packSize.height)
        } else {
            missingArtworkBadge
        }
    }

    var missingArtworkBadge: some View {
        Circle()
            .fill(DesignSystem.Color.bgTransparentPrimary)
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

    func glow(_ image: Image, packSize: CGSize) -> some View {
        image
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: packSize.width, height: packSize.height)
            .blur(radius: glow.blurRadius)
            .opacity(glow.opacity)
            .allowsHitTesting(false)
    }

    // MARK: - Calculations

    func scale(for packSize: CGSize) -> CGFloat {
        packSize.height / Metrics.referencePackHeight
    }
}

// MARK: - Glow

extension CollectiblesPackCard.Artwork {
    enum Glow {
        case card
        case page

        var blurRadius: CGFloat {
            switch self {
            case .card: 24
            case .page: 48
            }
        }

        var opacity: CGFloat {
            switch self {
            case .card: 0.8
            case .page: 1
            }
        }
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
        static let placeholderCornerRadius: CGFloat = 12
        static let artworkAspectRatio: CGFloat = 590 / 850
        static let fallbackBadgeSize: CGFloat = 40
        static let fallbackGlyphSize: CGFloat = 20
    }
}
