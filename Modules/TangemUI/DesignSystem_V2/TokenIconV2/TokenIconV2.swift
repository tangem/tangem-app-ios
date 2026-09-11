//
//  TokenIconV2.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import Kingfisher
import TangemAccessibilityIdentifiers
import TangemAssets
import TangemFoundation
import TangemUIUtils

public struct TokenIconV2: View {
    private let tokenIconInfo: TokenIconInfo
    private let size: Size

    private var indicatorColorValue: Color?
    private var geometryEffectValue: GeometryEffectPropertiesModel?
    private var isGrayscale: Bool = false
    private var accessibilityIdentifierValue: String?
    private var accessibilityLabelValue: String?

    @ScaledMetric private var scale: CGFloat = 1

    @State private var isLoaded = false

    // MARK: - Init

    public init(tokenIconInfo: TokenIconInfo, size: Size) {
        self.tokenIconInfo = tokenIconInfo
        self.size = size
    }

    // MARK: - Body

    public var body: some View {
        content
            .frame(size: CGSize(bothDimensions: metrics.container))
            .accessibilityElement(children: .ignore)
            .accessibilityIdentifier(accessibilityIdentifierValue)
            .accessibilityLabel(accessibilityLabelValue)
            // Only fully hide (removing it from the XCUITest tree) when the caller gave neither an
            // identifier nor a label — screens locate token icons by identifier.
            .accessibilityHidden(isDecorative)
            .overlay(alignment: .bottomTrailing) { if isResolved { indicator } }
            .saturation(isGrayscale ? 0 : 1)
            .opacity(isGrayscale ? Constants.grayscaleOpacity : 1)
            // A reused view whose URL mutates in place keeps `isLoaded`; drop the badge until the new
            // artwork resolves so it can't sit over the incoming shimmer.
            .onChange(of: tokenIconInfo.imageURL) { _ in
                isLoaded = false
            }
    }

    @ViewBuilder
    private var content: some View {
        if let customTokenColor = tokenIconInfo.customTokenColor {
            // Custom tokens have no remote logo; their identity is a color derived from the contract
            // address. It's the artwork and takes precedence over any URL, matching TokenIcon.
            customArtwork(color: customTokenColor)
        } else if let url = tokenIconInfo.imageURL {
            loadedArtwork(url: url)
        } else {
            // A nil URL would leave KFImage stuck on its placeholder forever, so it never reaches the
            // loader — the neutral glyph stands in directly.
            placeholderBody
        }
    }

    // MARK: - Artwork branches

    private var placeholderBody: some View {
        Circle()
            .fill(DesignSystem.Color.bgSecondary)
            .overlay {
                placeholderGlyph.image
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFill()
                    .foregroundStyle(DesignSystem.Color.iconTertiary)
                    .flipsForRightToLeftLayoutDirection(false)
            }
    }

    private var shimmerBody: some View {
        Shimmer()
            .clipShape(.circle)
    }

    // MARK: - Composition

    private func loadedArtwork(url: URL) -> some View {
        composedArtwork(showsOverlays: isLoaded) {
            KFImage(url)
                .appendProcessor(ContrastBackgroundImageProcessor(backgroundColor: IconViewDefaults.lowContrastBackgroundColor))
                .cancelOnDisappear(true)
                .placeholder { shimmerBody }
                .onFailureView { placeholderBody }
                .onSuccess { _ in isLoaded = true }
                .fade(duration: 0.3)
                .cacheOriginalImage()
                .resizable()
                .scaledToFit()
                .flipsForRightToLeftLayoutDirection(false)
        }
    }

    /// Custom-token identity artwork: the derived color as background, marked with the custom glyph.
    /// It's a resolved icon (not a placeholder), so it always carries the badge and indicator.
    private func customArtwork(color: Color) -> some View {
        composedArtwork(showsOverlays: true) {
            color.overlay {
                DesignSystem.Icons.tokenCustom.image
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFill()
                    .foregroundStyle(DesignSystem.Color.iconTertiary)
                    .flipsForRightToLeftLayoutDirection(false)
            }
        }
    }

    private func composedArtwork<Artwork: View>(showsOverlays: Bool, @ViewBuilder _ artwork: () -> Artwork) -> some View {
        artwork()
            .matchedGeometryEffect(geometryEffectValue)
            .frame(size: CGSize(bothDimensions: metrics.container))
            .clipShape(.circle)
            .modifier(IconCutouts(
                metrics: metrics,
                cutsNetworkHole: hasNetworkBadge && showsOverlays,
                cutsIndicatorHole: indicatorColor != nil && showsOverlays
            ))
            .overlay(alignment: .topTrailing) { if showsOverlays { networkBadge } }
    }

    @ViewBuilder
    private var networkBadge: some View {
        if hasNetworkBadge, let asset = tokenIconInfo.blockchainIconAsset {
            NetworkIcon(
                imageAsset: asset,
                isActive: true,
                isMainIndicatorVisible: false,
                showBackground: false,
                size: CGSize(bothDimensions: metrics.networkDiameter)
            )
            .frame(size: CGSize(bothDimensions: metrics.networkDiameter))
            // Anchor and `.offset(x:)` both flip under RTL (verified), so raw LTR values are correct.
            // Do NOT add a manual RTL sign flip — it double-mirrors and breaks RTL.
            .offset(x: metrics.networkOverhang, y: -metrics.networkOverhang)
        }
    }

    @ViewBuilder
    private var indicator: some View {
        if let color = indicatorColor {
            Circle()
                .fill(color)
                .frame(size: CGSize(bothDimensions: metrics.indicatorDiameter))
                .padding([.bottom, .trailing], metrics.indicatorInset)
                .accessibilityIdentifier(MainAccessibilityIdentifiers.tokenCustomIndicator(for: tokenIconInfo.name))
        }
    }

    // MARK: - Accessibility

    private var isDecorative: Bool {
        accessibilityIdentifierValue == nil && accessibilityLabelValue == nil
    }
}

// MARK: - Derived state

private extension TokenIconV2 {
    var hasNetworkBadge: Bool {
        tokenIconInfo.blockchainIconAsset != nil
    }

    var isResolved: Bool {
        if tokenIconInfo.customTokenColor != nil {
            return true
        }
        if tokenIconInfo.imageURL != nil {
            return isLoaded
        }
        return false
    }

    var placeholderGlyph: ImageType {
        tokenIconInfo.isCustom ? DesignSystem.Icons.tokenCustom : DesignSystem.Icons.tokenError
    }

    var indicatorColor: Color? {
        indicatorColorValue ?? (tokenIconInfo.isCustom ? DesignSystem.Color.iconTertiary : nil)
    }

    var clampedScale: CGFloat {
        TokenIconV2.clampedScale(scale)
    }

    var metrics: Metrics {
        size.baseMetrics.scaled(by: clampedScale)
    }
}

// MARK: - Setupable

extension TokenIconV2: Setupable {
    public func accessibilityIdentifier(_ id: String?) -> Self {
        map { $0.accessibilityIdentifierValue = id }
    }

    public func accessibilityLabel(_ label: String?) -> Self {
        map { $0.accessibilityLabelValue = label }
    }

    public func indicatorColor(_ color: Color) -> Self {
        map { $0.indicatorColorValue = color }
    }

    public func geometryEffect(_ effect: GeometryEffectPropertiesModel?) -> Self {
        map { $0.geometryEffectValue = effect }
    }

    public func grayscale(_ isGrayscale: Bool) -> Self {
        map { $0.isGrayscale = isGrayscale }
    }
}

// MARK: - Types

extension TokenIconV2 {
    enum Constants {
        static let grayscaleOpacity: CGFloat = 0.4
        static let minDynamicTypeMultiplier: CGFloat = 1
        static let maxDynamicTypeMultiplier: CGFloat = 1.5
    }

    static func clampedScale(_ scale: CGFloat) -> CGFloat {
        min(max(scale, Constants.minDynamicTypeMultiplier), Constants.maxDynamicTypeMultiplier)
    }
}

// MARK: - Cutouts

private struct IconCutouts: ViewModifier {
    let metrics: TokenIconV2.Metrics
    let cutsNetworkHole: Bool
    let cutsIndicatorHole: Bool

    /// Anchors and `.offset(x:)` both flip under RTL (verified), so raw LTR offsets keep each hole
    /// concentric with its element. Do NOT add a manual RTL sign flip — it double-mirrors and breaks RTL.
    func body(content: Content) -> some View {
        content.mask {
            Rectangle()
                .overlay(alignment: .topTrailing) { networkHole }
                .overlay(alignment: .bottomTrailing) { indicatorHole }
                .compositingGroup()
        }
    }

    @ViewBuilder
    private var networkHole: some View {
        if cutsNetworkHole {
            let outset = metrics.networkOverhang + metrics.cutoutGap

            Circle()
                .frame(size: CGSize(bothDimensions: metrics.cutoutDiameter))
                .offset(x: outset, y: -outset)
                .blendMode(.destinationOut)
        }
    }

    @ViewBuilder
    private var indicatorHole: some View {
        if cutsIndicatorHole {
            let inset = metrics.indicatorInset - metrics.cutoutGap

            Circle()
                .frame(size: CGSize(bothDimensions: metrics.indicatorCutoutDiameter))
                .offset(x: -inset, y: -inset)
                .blendMode(.destinationOut)
        }
    }
}
