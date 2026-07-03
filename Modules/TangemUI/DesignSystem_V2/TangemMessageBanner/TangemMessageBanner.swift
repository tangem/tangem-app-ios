//
//  TangemMessageBanner.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

/// Design-system v2 (DS3) **Message Banner** — a rounded card with a title/description text block,
/// optional leading/trailing/extra-bottom slots, an optional action-button row, and an animated glow ring.
///
/// [Figma]([REDACTED_INFO]
///
/// Behavior notes:
/// - The visual appearance (background color + glow-ring palette) is driven by ``variant(_:)``.
/// - ``contentAlign(_:)`` switches between a leading layout (`slotStart · text · slotEnd`) and a
///   centered layout where the text is centered and the slots float in the top corners.
/// - The button row is hidden entirely when neither ``primaryButton(_:)`` nor
///   ``secondaryButton(_:)`` is set; with both, they split the row evenly.
/// - The glow ring is drawn as an overlay and can be turned off with ``showGlowRing(_:)`` (e.g. to
///   avoid the per-frame redraw when the banner is off-screen or in a dense list).
///
/// Slots are supplied via the ``slotStart(_:)``, ``slotEnd(_:)`` and ``extraBottom(_:)`` transforms,
/// mirroring ``TangemRow``. Use ``closeButton(accessibilityLabel:action:)`` for the standard
/// dismiss affordance in the trailing slot.
///
/// ```swift
/// TangemMessageBanner(title: "Would you predict?", description: "France will win FIFA 2026")
///     .variant(.info)
///     .secondaryButton(.init(title: "Later", action: onLater))
///     .primaryButton(.init(title: "Predict", action: onPredict))
///     .closeButton(accessibilityLabel: "Dismiss", action: onDismiss)
/// ```
public struct TangemMessageBanner<SlotStart: View, SlotEnd: View, ExtraBottom: View>: View, Setupable {
    let title: String
    let description: String?

    let slotStartContent: SlotStart
    let slotEndContent: SlotEnd
    let extraBottomContent: ExtraBottom

    var config: TangemMessageBannerConfiguration

    init(
        title: String,
        description: String?,
        slotStart: SlotStart,
        slotEnd: SlotEnd,
        extraBottom: ExtraBottom,
        config: TangemMessageBannerConfiguration = TangemMessageBannerConfiguration()
    ) {
        self.title = title
        self.description = description
        slotStartContent = slotStart
        slotEndContent = slotEnd
        extraBottomContent = extraBottom
        self.config = config
    }

    public var body: some View {
        let banner = VStack(alignment: .leading, spacing: TangemMessageBannerMetrics.rootSpacing) {
            contentView
            buttonsView
        }
        .padding(TangemMessageBannerMetrics.contentPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(config.variant.background, in: containerShape)

        return applyGlowRing(to: banner)
    }

    private var containerShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: TangemMessageBannerMetrics.cornerRadius, style: .continuous)
    }

    @ViewBuilder
    private func applyGlowRing(to content: some View) -> some View {
        if config.showsGlowRing {
            content.glowRing(config.variant.glowAppearance, cornerRadius: TangemMessageBannerMetrics.cornerRadius)
        } else {
            content
        }
    }
}

// MARK: - Content

private extension TangemMessageBanner {
    @ViewBuilder
    var contentView: some View {
        switch config.contentAlign {
        case .start:
            HStack(alignment: .top, spacing: TangemMessageBannerMetrics.contentRowSpacing) {
                slotStartContent
                textColumn
                    .frame(maxWidth: .infinity, alignment: .leading)
                slotEndContent
            }
        case .center:
            textColumn
                .frame(maxWidth: .infinity)
                .padding(.horizontal, TangemMessageBannerMetrics.centerTextHorizontalPadding)
                .overlay(alignment: .topLeading) { slotStartContent }
                .overlay(alignment: .topTrailing) { slotEndContent }
        }
    }

    var textColumn: some View {
        VStack(alignment: config.contentAlign.textStackAlignment, spacing: TangemMessageBannerMetrics.textColumnSpacing) {
            Text(title)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                .lineLimit(TangemMessageBannerMetrics.titleLineLimit)
                .truncationMode(.tail)
                .multilineTextAlignment(config.contentAlign.textAlignment)

            if let description {
                Text(description)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .multilineTextAlignment(config.contentAlign.textAlignment)
            }

            if ExtraBottom.self != EmptyView.self {
                extraBottomContent
                    .padding(.top, TangemMessageBannerMetrics.extraBottomTopPadding)
            }
        }
        .ifLet(config.accessibilityLabel) { view, label in
            view
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(label)
        }
    }
}

// MARK: - Buttons

private extension TangemMessageBanner {
    @ViewBuilder
    var buttonsView: some View {
        if config.secondaryButton != nil || config.primaryButton != nil {
            HStack(spacing: TangemMessageBannerMetrics.buttonRowSpacing) {
                if let secondaryButton = config.secondaryButton {
                    buttonView(secondaryButton, styleType: .secondary)
                }

                if let primaryButton = config.primaryButton {
                    buttonView(primaryButton, styleType: .default)
                }
            }
        }
    }

    func buttonView(_ model: TangemMessageBannerButton, styleType: TangemButtonV2.StyleType) -> some View {
        TangemButtonV2(
            label: AttributedString(model.title),
            iconStart: model.iconStart,
            iconEnd: model.iconEnd,
            accessibilityLabel: model.accessibilityLabel ?? model.title,
            action: model.action
        )
        .styleType(styleType)
        .horizontalLayout(.infinity)
        .isLoading(model.isLoading)
        .disabled(!model.isEnabled)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Variant tokens

extension TangemMessageBannerVariant {
    var background: Color {
        switch self {
        case .default: DesignSystem.Color.bgOpaquePrimary
        case .solid: DesignSystem.Color.bgTertiary
        case .success: DesignSystem.Color.bgStatusSuccessSubtle
        case .error: DesignSystem.Color.bgStatusErrorSubtle
        case .warning: DesignSystem.Color.bgStatusWarningSubtle
        case .info: DesignSystem.Color.bgStatusInfoSubtle
        }
    }

    var glowAppearance: GlowRingAppearance {
        switch self {
        case .default, .solid: .magic
        case .success: .success
        case .error: .error
        case .warning: .warning
        case .info: .info
        }
    }
}

// MARK: - Constants

enum TangemMessageBannerMetrics {
    static let cornerRadius: CGFloat = 28
    static let contentPadding: CGFloat = 16
    static let rootSpacing: CGFloat = 24
    static let contentRowSpacing: CGFloat = 12
    static let textColumnSpacing: CGFloat = 4
    static let extraBottomTopPadding: CGFloat = 12
    static let buttonRowSpacing: CGFloat = 8
    static let centerTextHorizontalPadding: CGFloat = 32
    static let closeButtonSize: CGFloat = 20
    static let titleLineLimit: Int = 2
}
