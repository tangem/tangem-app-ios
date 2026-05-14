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

/// A capsule-shaped, label-centric badge with optional leading/trailing slots.
///
/// Use ``size(_:)`` to pick one of the three discrete sizes (x9 / x6 / x4),
/// ``variant(_:)`` for tinted / solid / outline, and ``appearance(_:)`` for
/// neutral / info / error / warning / success. Defaults match the Figma
/// component: size `.x6`, variant `.tinted`, appearance `.neutral`, both
/// slots empty.
///
/// Slots accept arbitrary SwiftUI content via the ``slotStart(_:)-(()->_)`` /
/// ``slotEnd(_:)-(()->_)`` ViewBuilder modifiers. The badge stamps a
/// `.frame(height:)` matching its size tier on slot content so Dynamic Type
/// stays consistent; colors, shapes, and styles are the consumer's concern.
///
/// For the common case of an `ImageType` icon, the ``slotStart(_:)-(ImageType?)``
/// / ``slotEnd(_:)-(ImageType?)`` overloads re-apply the template-tint
/// pipeline so the icon picks up the badge's current `iconColor`.
///
/// ```swift
/// TangemBadgeV2(label: "Live")
///     .appearance(.success)
///     .slotStart(DesignSystem.Icons.SignEqual.regular16)
///
/// TangemBadgeV2(label: "Loading")
///     .slotStart { ProgressView().controlSize(.mini) }
/// ```
public struct TangemBadgeV2<SlotStart: View, SlotEnd: View>: View, Setupable {
    private let label: String
    private let slotStartContent: SlotStart
    private let slotEndContent: SlotEnd

    private var size: Size = .x6
    private var variant: Variant = .tinted
    private var appearance: Appearance = .neutral
    private var accessibilityLabel: String?

    @ScaledMetric private var minHeight: CGFloat
    @ScaledMetric private var iconSize: CGFloat
    @ScaledMetric private var outerHorizontalPadding: CGFloat
    @ScaledMetric private var outerVerticalPadding: CGFloat
    @ScaledMetric private var labelHorizontalPadding: CGFloat

    fileprivate init(
        label: String,
        size: Size = .x6,
        variant: Variant = .tinted,
        appearance: Appearance = .neutral,
        accessibilityLabel: String? = nil,
        slotStart: SlotStart,
        slotEnd: SlotEnd
    ) {
        self.label = label
        self.size = size
        self.variant = variant
        self.appearance = appearance
        self.accessibilityLabel = accessibilityLabel
        slotStartContent = slotStart
        slotEndContent = slotEnd

        _minHeight = ScaledMetric(wrappedValue: size.baseMinHeight)
        _iconSize = ScaledMetric(wrappedValue: size.baseIconSize)
        _outerHorizontalPadding = ScaledMetric(wrappedValue: size.baseOuterHorizontalPadding)
        _outerVerticalPadding = ScaledMetric(wrappedValue: size.baseOuterVerticalPadding)
        _labelHorizontalPadding = ScaledMetric(wrappedValue: size.baseLabelHorizontalPadding)
    }

    public var body: some View {
        HStack(spacing: 0) {
            slotStartContent
                .frame(height: iconSize)

            Text(label)
                .style(size.font, color: textColor)
                .lineLimit(1)
                .truncationMode(.tail)
                .padding(.horizontal, labelHorizontalPadding)

            slotEndContent
                .frame(height: iconSize)
        }
        .padding(.horizontal, outerHorizontalPadding)
        .padding(.vertical, outerVerticalPadding)
        .frame(minHeight: minHeight)
        .background(backgroundColor, in: Capsule())
        .overlay { borderOverlay }
        .environment(\.tangemBadgeV2IconColor, iconColor)
        .accessibilityElement(children: .combine)
        .ifLet(accessibilityLabel) { view, label in
            view.accessibilityLabel(Text(label))
        }
    }

    @ViewBuilder
    private var borderOverlay: some View {
        if let borderColor {
            Capsule().stroke(borderColor, lineWidth: 1)
        }
    }
}

// MARK: - Empty-slot Init

public extension TangemBadgeV2 where SlotStart == EmptyView, SlotEnd == EmptyView {
    init(label: String, accessibilityLabel: String?) {
        self.init(
            label: label,
            accessibilityLabel: accessibilityLabel,
            slotStart: EmptyView(),
            slotEnd: EmptyView()
        )
    }
}

// MARK: - Setupable Modifiers

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

    func accessibilityLabel(_ label: String?) -> Self {
        map { $0.accessibilityLabel = label }
    }
}

// MARK: - Slot Transforms

public extension TangemBadgeV2 {
    func slotStart<V: View>(@ViewBuilder _ content: () -> V) -> TangemBadgeV2<V, SlotEnd> {
        TangemBadgeV2<V, SlotEnd>(
            label: label,
            size: size,
            variant: variant,
            appearance: appearance,
            accessibilityLabel: accessibilityLabel,
            slotStart: content(),
            slotEnd: slotEndContent
        )
    }

    func slotEnd<V: View>(@ViewBuilder _ content: () -> V) -> TangemBadgeV2<SlotStart, V> {
        TangemBadgeV2<SlotStart, V>(
            label: label,
            size: size,
            variant: variant,
            appearance: appearance,
            accessibilityLabel: accessibilityLabel,
            slotStart: slotStartContent,
            slotEnd: content()
        )
    }

    func slotStart(_ icon: ImageType?) -> TangemBadgeV2<some View, SlotEnd> {
        slotStart {
            if let icon {
                AutoTintedSlotIcon(icon: icon)
            }
        }
    }

    func slotEnd(_ icon: ImageType?) -> TangemBadgeV2<SlotStart, some View> {
        slotEnd {
            if let icon {
                AutoTintedSlotIcon(icon: icon)
            }
        }
    }
}

// MARK: - Public Type

public enum TangemBadgeV2Size: Sendable, Hashable, CaseIterable {
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

public enum TangemBadgeV2Variant: Sendable, Hashable, CaseIterable {
    case tinted
    case solid
    case outline
}

public enum TangemBadgeV2Appearance: Sendable, Hashable, CaseIterable {
    case neutral
    case info
    case error
    case warning
    case success
}

public extension TangemBadgeV2 {
    typealias Size = TangemBadgeV2Size
    typealias Variant = TangemBadgeV2Variant
    typealias Appearance = TangemBadgeV2Appearance
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

private extension TangemBadgeV2Appearance {
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

// MARK: - Auto-tinted Slot Icon

private struct AutoTintedSlotIcon: View {
    let icon: ImageType

    @Environment(\.tangemBadgeV2IconColor) private var iconColor

    var body: some View {
        icon.image
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundStyle(iconColor)
    }
}

// MARK: - Environment

private struct TangemBadgeV2IconColorKey: EnvironmentKey {
    static let defaultValue: Color = .primary
}

private extension EnvironmentValues {
    var tangemBadgeV2IconColor: Color {
        get { self[TangemBadgeV2IconColorKey.self] }
        set { self[TangemBadgeV2IconColorKey.self] = newValue }
    }
}
