//
//  TangemBadgeV2.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

/// A capsule-shaped, label-centric badge with optional leading/trailing icon slots.
///
/// Use ``size(_:)`` to pick one of the three discrete sizes (x9 / x6 / x4),
/// ``variant(_:)`` for tinted / solid / outline, and ``appearance(_:)`` for
/// neutral / info / error / warning / success. Attach icons via ``slotStart(_:)`` /
/// ``slotEnd(_:)``. Defaults match the Figma component: size `.x6`, variant `.tinted`,
/// appearance `.neutral`, both slots empty.
///
/// ```swift
/// TangemBadgeV2(label: "Live")
///     .appearance(.success)
///     .slotStart(DesignSystem.Icons.SignEqual.regular16)
/// ```
public struct TangemBadgeV2: View, Setupable {
    private let label: String

    private var size: Size = .x6
    private var variant: Variant = .tinted
    private var appearance: Appearance = .neutral
    private var slotStartIcon: ImageType?
    private var slotEndIcon: ImageType?
    private var accessibilityLabel: String?

    @ScaledMetric private var minHeight: CGFloat
    @ScaledMetric private var iconSize: CGFloat
    @ScaledMetric private var outerHorizontalPadding: CGFloat
    @ScaledMetric private var outerVerticalPadding: CGFloat
    @ScaledMetric private var labelHorizontalPadding: CGFloat

    public init(label: String, accessibilityLabel: String?) {
        self.label = label
        self.accessibilityLabel = accessibilityLabel

        let defaultSize = Size.x6
        _minHeight = ScaledMetric(wrappedValue: defaultSize.baseMinHeight)
        _iconSize = ScaledMetric(wrappedValue: defaultSize.baseIconSize)
        _outerHorizontalPadding = ScaledMetric(wrappedValue: defaultSize.baseOuterHorizontalPadding)
        _outerVerticalPadding = ScaledMetric(wrappedValue: defaultSize.baseOuterVerticalPadding)
        _labelHorizontalPadding = ScaledMetric(wrappedValue: defaultSize.baseLabelHorizontalPadding)
    }

    public var body: some View {
        HStack(spacing: 0) {
            slotIcon(slotStartIcon)

            Text(label)
                .style(size.font, color: textColor)
                .lineLimit(1)
                .truncationMode(.tail)
                .padding(.horizontal, labelHorizontalPadding)

            slotIcon(slotEndIcon)
        }
        .padding(.horizontal, outerHorizontalPadding)
        .padding(.vertical, outerVerticalPadding)
        .frame(minHeight: minHeight)
        .background(backgroundColor, in: Capsule())
        .overlay { borderOverlay }
        .ifLet(accessibilityLabel) { view, label in
            view.accessibilityLabel(Text(label))
        }
    }

    @ViewBuilder
    private func slotIcon(_ icon: ImageType?) -> some View {
        if let icon {
            icon.image
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: iconSize, height: iconSize)
                .foregroundStyle(iconColor)
        }
    }

    @ViewBuilder
    private var borderOverlay: some View {
        if let borderColor {
            Capsule().stroke(borderColor, lineWidth: 1)
        }
    }
}

// MARK: - Setupable

public extension TangemBadgeV2 {
    func size(_ size: Size) -> Self {
        map { copy in
            copy.size = size
            copy._minHeight = ScaledMetric(wrappedValue: size.baseMinHeight)
            copy._iconSize = ScaledMetric(wrappedValue: size.baseIconSize)
            copy._outerHorizontalPadding = ScaledMetric(wrappedValue: size.baseOuterHorizontalPadding)
            copy._outerVerticalPadding = ScaledMetric(wrappedValue: size.baseOuterVerticalPadding)
            copy._labelHorizontalPadding = ScaledMetric(wrappedValue: size.baseLabelHorizontalPadding)
        }
    }

    func variant(_ variant: Variant) -> Self {
        map { $0.variant = variant }
    }

    func appearance(_ appearance: Appearance) -> Self {
        map { $0.appearance = appearance }
    }

    func slotStart(_ icon: ImageType?) -> Self {
        map { $0.slotStartIcon = icon }
    }

    func slotEnd(_ icon: ImageType?) -> Self {
        map { $0.slotEndIcon = icon }
    }

    func accessibilityLabel(_ label: String?) -> Self {
        map { $0.accessibilityLabel = label }
    }
}

// MARK: - Public Types

public extension TangemBadgeV2 {
    enum Size: Sendable, Hashable, CaseIterable {
        case x9
        case x6
        case x4

        var baseMinHeight: CGFloat {
            switch self {
            case .x9: DesignSystem.Tokens.Size.s450
            case .x6: DesignSystem.Tokens.Size.s300
            case .x4: DesignSystem.Tokens.Size.s200
            }
        }

        var baseIconSize: CGFloat {
            switch self {
            case .x9: DesignSystem.Tokens.Size.s250
            case .x6: DesignSystem.Tokens.Size.s200
            case .x4: DesignSystem.Tokens.Size.s150
            }
        }

        var baseOuterHorizontalPadding: CGFloat {
            switch self {
            case .x9: DesignSystem.Tokens.Spacing.s100
            case .x6: DesignSystem.Tokens.Spacing.s050
            case .x4: DesignSystem.Tokens.Spacing.s025
            }
        }

        var baseOuterVerticalPadding: CGFloat {
            switch self {
            case .x9: DesignSystem.Tokens.Spacing.s100
            case .x6: DesignSystem.Tokens.Spacing.s050
            case .x4: DesignSystem.Tokens.Spacing.none
            }
        }

        var baseLabelHorizontalPadding: CGFloat {
            switch self {
            case .x9: DesignSystem.Tokens.Spacing.s050
            case .x6: DesignSystem.Tokens.Spacing.s050
            case .x4: DesignSystem.Tokens.Spacing.s025
            }
        }

        var font: TangemTypographyToken {
            switch self {
            case .x9: DesignSystem.Tokens.Font.Subheading.medium
            case .x6, .x4: DesignSystem.Tokens.Font.Caption.medium
            }
        }
    }

    enum Variant: Sendable, Hashable, CaseIterable {
        case tinted
        case solid
        case outline
    }

    enum Appearance: Sendable, Hashable, CaseIterable {
        case neutral
        case info
        case error
        case warning
        case success
    }
}

// MARK: - Style Matrix

private extension TangemBadgeV2 {
    /// Three visual states span the variant × appearance space. Picking a state
    /// is what reduces the 15-cell matrix to a handful of branches per style.
    enum VisualState {
        /// tinted/outline + any appearance → muted bg with status-tinted content.
        case subtle
        /// solid + neutral → muted bg shared with subtle, but high-contrast primary content.
        case loudNeutral
        /// solid + status → full-saturation status bg with white-ish content.
        case saturated
    }

    var state: VisualState {
        switch (variant, appearance) {
        case (.solid, .neutral): .loudNeutral
        case (.solid, _): .saturated
        default: .subtle
        }
    }

    var backgroundColor: Color {
        switch state {
        case .subtle, .loudNeutral: appearance.palette.subtleBackground
        case .saturated: appearance.palette.solidBackground
        }
    }

    var borderColor: Color? {
        variant == .outline ? appearance.palette.outlineBorder : nil
    }

    var textColor: Color {
        switch state {
        case .subtle: appearance.palette.subtleContent
        case .loudNeutral: DesignSystem.Tokens.Theme.Text.primary
        case .saturated: DesignSystem.Tokens.Theme.Text.StaticDark.primary
        }
    }

    var iconColor: Color {
        switch state {
        case .subtle: appearance.palette.subtleIcon
        case .loudNeutral: DesignSystem.Tokens.Theme.Icon.primary
        case .saturated: DesignSystem.Tokens.Theme.Icon.staticDark
        }
    }
}

// MARK: - Appearance Palette

private struct AppearancePalette {
    let solidBackground: Color
    let subtleBackground: Color
    let outlineBorder: Color
    let subtleContent: Color
    let subtleIcon: Color
}

private extension TangemBadgeV2.Appearance {
    var palette: AppearancePalette {
        switch self {
        case .neutral:
            AppearancePalette(
                solidBackground: DesignSystem.Tokens.Theme.Bg.Opaque.primary,
                subtleBackground: DesignSystem.Tokens.Theme.Bg.Opaque.primary,
                outlineBorder: DesignSystem.Tokens.Theme.Border.primary,
                subtleContent: DesignSystem.Tokens.Theme.Text.secondary,
                subtleIcon: DesignSystem.Tokens.Theme.Icon.secondary
            )
        case .info:
            AppearancePalette(
                solidBackground: DesignSystem.Tokens.Theme.Bg.Status.info,
                subtleBackground: DesignSystem.Tokens.Theme.Bg.Status.infoSubtle,
                outlineBorder: DesignSystem.Tokens.Theme.Border.Status.infoSubtle,
                subtleContent: DesignSystem.Tokens.Theme.Text.Status.info,
                subtleIcon: DesignSystem.Tokens.Theme.Icon.Status.info
            )
        case .error:
            AppearancePalette(
                solidBackground: DesignSystem.Tokens.Theme.Bg.Status.error,
                subtleBackground: DesignSystem.Tokens.Theme.Bg.Status.errorSubtle,
                outlineBorder: DesignSystem.Tokens.Theme.Border.Status.errorSubtle,
                subtleContent: DesignSystem.Tokens.Theme.Text.Status.error,
                subtleIcon: DesignSystem.Tokens.Theme.Icon.Status.error
            )
        case .warning:
            AppearancePalette(
                solidBackground: DesignSystem.Tokens.Theme.Bg.Status.warning,
                subtleBackground: DesignSystem.Tokens.Theme.Bg.Status.warningSubtle,
                outlineBorder: DesignSystem.Tokens.Theme.Border.Status.warningSubtle,
                subtleContent: DesignSystem.Tokens.Theme.Text.Status.warning,
                subtleIcon: DesignSystem.Tokens.Theme.Icon.Status.warning
            )
        case .success:
            AppearancePalette(
                solidBackground: DesignSystem.Tokens.Theme.Bg.Status.success,
                subtleBackground: DesignSystem.Tokens.Theme.Bg.Status.successSubtle,
                outlineBorder: DesignSystem.Tokens.Theme.Border.Status.successSubtle,
                subtleContent: DesignSystem.Tokens.Theme.Text.Status.success,
                subtleIcon: DesignSystem.Tokens.Theme.Icon.Status.success
            )
        }
    }
}
