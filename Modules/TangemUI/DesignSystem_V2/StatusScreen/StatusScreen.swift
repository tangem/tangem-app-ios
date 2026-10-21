//
//  StatusScreen.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils
import UIKit

/// Design-system v2 full-screen status layout: a tinted gradient background, a colored
/// glow ring hugging the screen edges, a draw-on animated status icon, a title with an
/// optional description, and optional slots for a badge, details rows, and a pinned
/// footer over a bottom fade.
///
/// [Figma]([REDACTED_INFO]
///
/// Use ``appearance(_:)`` to pick one of the five variants (neutral / success / error /
/// warning / info) — it drives the background tint, the glow ring palette, and the
/// default icon. The screen always ends with an action button pinned over the bottom
/// fade — pass its title and action in the initializer, and add
/// ``secondaryAction(title:action:)`` for a secondary button above it. Slots accept
/// arbitrary SwiftUI content via the ViewBuilder modifiers: ``assetSlot(_:)`` replaces the default
/// ``StatusIcon``, ``headerAccessory(_:)`` sits under the texts (a `Badge` in the
/// reference design), and ``details(_:)`` is the place for `Row`-based key-value content.
///
/// ```swift
/// StatusScreen(
///     title: "Sent!",
///     description: "Your transaction is on its way",
///     actionTitle: "Done",
///     action: onDone
/// )
/// .appearance(.success)
/// .details {
///     VStack(spacing: 0) {
///         Row(title: "Amount", value: "0.1 BTC").showDivider()
///         Row(title: "Fee", value: "$1.02")
///     }
/// }
/// ```
public struct StatusScreen<AssetSlot: View, HeaderAccessory: View, Details: View>: View, Setupable {
    let title: String
    let description: String?
    let actionTitle: String
    let action: () -> Void
    let assetSlotContent: AssetSlot
    let headerAccessoryContent: HeaderAccessory
    let detailsContent: Details

    var appearance: StatusScreenAppearance = .neutral
    var secondaryAction: StatusScreenSecondaryAction?
    var footerCaption: String?
    var actionIcon: ImageType?
    var actionSigningType: SigningActionButtonViewType?
    var isActionLoading = false
    var isActionDisabled = false
    var footerAxis: StatusScreenFooterAxis = .vertical
    var isFooterHidden = false

    init(
        title: String,
        description: String?,
        actionTitle: String,
        action: @escaping () -> Void,
        appearance: StatusScreenAppearance = .neutral,
        secondaryAction: StatusScreenSecondaryAction? = nil,
        assetSlot: AssetSlot,
        headerAccessory: HeaderAccessory,
        details: Details
    ) {
        self.title = title
        self.description = description
        self.actionTitle = actionTitle
        self.action = action
        self.appearance = appearance
        self.secondaryAction = secondaryAction
        assetSlotContent = assetSlot
        headerAccessoryContent = headerAccessory
        detailsContent = details
    }

    private let layout = StatusScreenLayout.current

    @State private var entrance = EntranceState()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var probedCornerRadius: CGFloat?
    @Environment(\.containerCornerRadius) private var announcedCornerRadius

    /// The footer takes part in the layout from the first frame, overlapping the content by
    /// its fade strip (see `StatusScreenMetrics`), so the centered header stays put while
    /// the footer and details fade in.
    public var body: some View {
        VStack(spacing: -Metrics.footerContentOverlap) {
            VStack(spacing: 0) {
                header
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                details
            }
            .padding(.bottom, Metrics.contentFooterBaseInset)

            if !isFooterHidden {
                footer
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { background }
        .background { ContainerCornerRadiusReader { probedCornerRadius = $0 } }
        .onAppear(perform: startEntrance)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: layout.headerSpacing) {
            assetSlot

            textsWrapper

            if HeaderAccessory.self != EmptyView.self {
                headerAccessoryContent
                    .opacity(entrance.isSecondaryTextVisible ? 1 : 0)
            }
        }
        .padding(.top, layout.headerTopPadding)
        .padding(.bottom, layout.headerBottomPadding)
        .padding(.horizontal, Metrics.headerHorizontalPadding)
    }

    @ViewBuilder
    private var assetSlot: some View {
        if AssetSlot.self == EmptyView.self {
            StatusIcon(appearance.iconGlyph)
                .startDelay(Animations.assetSlotDelay)
        } else {
            assetSlotContent
                .opacity(entrance.isAssetSlotFadedIn ? 1 : 0)
                .offset(y: entrance.isAssetSlotSettled ? 0 : Metrics.assetSlotEntranceOffset)
        }
    }

    private var textsWrapper: some View {
        VStack(spacing: Metrics.textSpacing) {
            Text(title)
                .style(DesignSystem.Font.headingMediumToken, color: DesignSystem.Color.textPrimary)

            if let description {
                Text(description)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .opacity(entrance.isSecondaryTextVisible ? 1 : 0)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Details

    @ViewBuilder
    private var details: some View {
        if Details.self != EmptyView.self {
            detailsContent
                .frame(maxWidth: .infinity)
                // The details area is fixed-height in the design; the flexible header above
                // gives way — otherwise tall content gets its texts squeezed to one line.
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Metrics.detailsHorizontalPadding)
                .padding(.vertical, layout.detailsVerticalPadding)
                .opacity(entrance.isDetailsVisible ? 1 : 0)
        }
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: Metrics.footerCaptionSpacing) {
            if let footerCaption {
                Text(footerCaption)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }

            buttons
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Metrics.footerHorizontalPadding)
        .padding(.top, layout.footerTopPadding)
        .padding(.bottom, layout.footerBottomPadding)
        .background {
            Fade(position: .bottom)
                .ignoresSafeArea(edges: .bottom)
        }
        .opacity(entrance.isFooterFadedIn ? 1 : 0)
        .offset(y: entrance.isFooterSettled ? 0 : Metrics.footerEntranceOffset)
    }

    private var buttons: some View {
        AxisStack(axis: footerAxis, spacing: Metrics.footerButtonSpacing) {
            if let secondaryAction {
                Button(
                    label: secondaryAction.title,
                    accessibilityLabel: secondaryAction.title,
                    action: secondaryAction.action
                )
                .size(.x12)
                .styleType(.secondary(.default))
                .horizontalLayout(.infinity)
            }

            if let actionSigningType {
                SigningActionButtonView(
                    type: actionSigningType,
                    title: actionTitle,
                    isLoading: isActionLoading,
                    isDisabled: isActionDisabled,
                    action: action
                )
            } else {
                Button(label: actionTitle, accessibilityLabel: actionTitle, action: action)
                    .iconEnd(actionIcon)
                    .size(.x12)
                    .styleType(.primary)
                    .horizontalLayout(.infinity)
                    .loading(.spinner(if: isActionLoading))
                    .disabled(isActionDisabled)
            }
        }
    }

    // MARK: - Background

    private var background: some View {
        ZStack(alignment: .top) {
            circle(
                color: appearance.backgroundPalette.dimCircle,
                opacity: Metrics.dimCircleOpacity,
                blur: Metrics.dimCircleBlur,
                offset: Metrics.dimCircleOffset
            )

            circle(
                color: appearance.backgroundPalette.accentCircle,
                opacity: Metrics.accentCircleOpacity,
                blur: Metrics.accentCircleBlur,
                offset: Metrics.accentCircleOffset
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(DesignSystem.Color.bgPrimary)
        .glowRing(
            appearance.glowRingAppearance,
            size: .fullscreen(cornerRadius: probedCornerRadius ?? announcedCornerRadius),
            isVisible: entrance.isGlowRingVisible
        )
        .ignoresSafeArea()
    }

    private func circle(color: Color, opacity: Double, blur: CGFloat, offset: CGPoint) -> some View {
        Circle()
            .fill(color.opacity(opacity))
            .frame(width: Metrics.circleSize, height: Metrics.circleSize)
            .offset(x: offset.x, y: offset.y)
            .blur(radius: blur)
            .scaleEffect(entrance.areCirclesVisible ? 1 : Metrics.circleEntranceScale)
            .opacity(entrance.areCirclesVisible ? 1 : 0)
    }

    // MARK: - Entrance

    private func startEntrance() {
        guard !reduceMotion else {
            entrance = .settled
            return
        }

        withAnimation(Animations.assetSlotFade) { entrance.isAssetSlotFadedIn = true }
        withAnimation(Animations.assetSlotSettle) { entrance.isAssetSlotSettled = true }
        withAnimation(Animations.secondaryTextReveal) { entrance.isSecondaryTextVisible = true }
        withAnimation(Animations.detailsFade) { entrance.isDetailsVisible = true }
        withAnimation(Animations.circlesReveal) { entrance.areCirclesVisible = true }
        withAnimation(Animations.glowRingReveal) { entrance.isGlowRingVisible = true }
        withAnimation(Animations.footerFade) { entrance.isFooterFadedIn = true }
        withAnimation(Animations.footerSettle) { entrance.isFooterSettled = true }
    }
}

// MARK: - Footer axis

public enum StatusScreenFooterAxis: Sendable, Hashable {
    case vertical
    case horizontal
}

private struct AxisStack<Content: View>: View {
    let axis: StatusScreenFooterAxis
    let spacing: CGFloat
    @ViewBuilder let content: Content

    var body: some View {
        switch axis {
        case .vertical: VStack(spacing: spacing) { content }
        case .horizontal: HStack(spacing: spacing) { content }
        }
    }
}

// MARK: - Entrance state

private struct EntranceState {
    var isAssetSlotFadedIn = false
    var isAssetSlotSettled = false
    var isSecondaryTextVisible = false
    var isDetailsVisible = false
    var areCirclesVisible = false
    var isGlowRingVisible = false
    var isFooterFadedIn = false
    var isFooterSettled = false

    static let settled: Self = .init(
        isAssetSlotFadedIn: true,
        isAssetSlotSettled: true,
        isSecondaryTextVisible: true,
        isDetailsVisible: true,
        areCirclesVisible: true,
        isGlowRingVisible: true,
        isFooterFadedIn: true,
        isFooterSettled: true
    )
}

// MARK: - Animations

/// Entrance choreography measured frame-by-frame from the exported Figma preview
/// (`export_video` of the Animation section, 60 fps): the icon draws at 430–900 ms
/// (incl. bounce), the description/badge fade in right as the drawing finishes
/// (570–730 ms), then the second act from 1000 ms — background circles, the glow ring
/// and details fade in, and the footer rises from the bottom edge at 1150–1400 ms. Unlike
/// the Figma preview, the layout is fixed from the first frame on purpose: the title doesn't
/// ease down and the content area doesn't squeeze, so the header never moves.
private enum StatusScreenAnimations {
    static let assetSlotDelay: TimeInterval = 0.3
    static let assetSlotFade = Animation.timingCurve(0.5, 0, 0.5, 1, duration: 0.3).delay(assetSlotDelay)
    static let assetSlotSettle = Animation.timingCurve(0.45, 1.45, 0.8, 1, duration: 0.3).delay(assetSlotDelay)
    static let secondaryTextReveal = Animation.easeInOut(duration: 0.16).delay(0.57)
    static let detailsFade = Animation.easeInOut(duration: 0.2).delay(1.0)
    static let circlesReveal = Animation.easeInOut(duration: 0.4).delay(1.0)
    static let glowRingReveal = Animation.timingCurve(0.5, 0, 0.5, 1, duration: 0.2).delay(1.0)
    static let footerFade = Animation.easeInOut(duration: 0.2).delay(1.15)
    static let footerSettle = Animation.timingCurve(0, 0.4, 0.3, 1, duration: 0.25).delay(1.15)
}

// MARK: - Layout size

/// The reference spacing assumes a screen tall enough to hold it: on the home-button devices
/// the header overruns its slot and rides up under the status bar, and the glow ring's
/// rounded clip carves corners out of a display that has square ones. `compact` retunes the
/// vertical rhythm for those; the footer keeps its overall height in both sizes, so the
/// strip the content reserves for it is the same.
private enum StatusScreenLayout {
    case compact
    case regular

    /// SE 2/3 and the 8 are 667 pt tall, the 8 Plus is 736; the next family up starts at 812.
    private static let compactHeightThreshold: CGFloat = 780

    static var current: Self {
        UIScreen.main.bounds.height < compactHeightThreshold ? .compact : .regular
    }

    var headerTopPadding: CGFloat {
        switch self {
        case .compact: 24
        case .regular: 48
        }
    }

    var headerBottomPadding: CGFloat {
        switch self {
        case .compact: 20
        case .regular: 56
        }
    }

    var headerSpacing: CGFloat {
        switch self {
        case .compact: 16
        case .regular: 20
        }
    }

    var detailsVerticalPadding: CGFloat {
        switch self {
        case .compact: 0
        case .regular: 8
        }
    }

    var footerTopPadding: CGFloat {
        switch self {
        case .compact: 12
        case .regular: 8
        }
    }

    /// Devices without a home indicator get no system inset under the button, so the gap to
    /// the physical edge has to come from here.
    var footerBottomPadding: CGFloat {
        switch self {
        case .compact: 20
        case .regular: 8
        }
    }
}

// MARK: - Metrics

private extension StatusScreen {
    typealias Metrics = StatusScreenMetrics
    typealias Animations = StatusScreenAnimations
}

private enum StatusScreenMetrics {
    static let headerHorizontalPadding: CGFloat = 24
    static let textSpacing: CGFloat = 8

    static let detailsHorizontalPadding: CGFloat = 16

    static let footerHorizontalPadding: CGFloat = 16
    static let footerButtonSpacing: CGFloat = 8
    static let footerCaptionSpacing: CGFloat = 12
    /// The footer overlaps the content by a fixed fade strip. Figma squeezes the content
    /// area from 820 to 760 pt when the footer arrives; the app keeps the 760 pt layout
    /// from the first frame instead, on purpose, so the header never jumps.
    static let contentFooterBaseInset: CGFloat = 20
    static let footerContentOverlap: CGFloat = 20

    static let circleSize: CGFloat = 360
    static let dimCircleOpacity: Double = 0.1
    static let dimCircleBlur: CGFloat = 128
    static let dimCircleOffset = CGPoint(x: -85, y: -64)
    static let accentCircleOpacity: Double = 0.4
    static let accentCircleBlur: CGFloat = 96
    static let accentCircleOffset = CGPoint(x: 233, y: -148)
    static let circleEntranceScale: CGFloat = 0.4

    static let assetSlotEntranceOffset: CGFloat = 36
    static let footerEntranceOffset: CGFloat = 90
}

// MARK: - Container corner radius

private extension CACornerMask {
    static let allCorners: CACornerMask = [
        .layerMinXMinYCorner,
        .layerMaxXMinYCorner,
        .layerMinXMaxYCorner,
        .layerMaxXMaxYCorner,
    ]
}

private struct ContainerCornerRadiusReader: UIViewRepresentable {
    let onChange: (CGFloat?) -> Void

    func makeUIView(context: Context) -> ProbeView {
        ProbeView(onChange: onChange)
    }

    func updateUIView(_ uiView: ProbeView, context: Context) {}
}

private extension ContainerCornerRadiusReader {
    final class ProbeView: UIView {
        private let onChange: (CGFloat?) -> Void
        private var reported: CGFloat??

        init(onChange: @escaping (CGFloat?) -> Void) {
            self.onChange = onChange
            super.init(frame: .zero)
            isUserInteractionEnabled = false
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            report()
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            report()
        }

        private func report() {
            let radius = sequence(first: self, next: \.superview)
                .first { $0.layer.cornerRadius > 0 && $0.layer.maskedCorners == .allCorners }?
                .layer.cornerRadius

            guard reported != .some(radius) else { return }

            reported = .some(radius)

            DispatchQueue.main.async { [onChange] in
                onChange(radius)
            }
        }
    }
}
