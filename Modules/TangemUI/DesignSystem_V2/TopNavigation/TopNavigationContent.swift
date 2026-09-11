//
//  TopNavigationContent.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

// MARK: - Title content

public struct TopNavigationTitleContent: View {
    private let title: String
    private let subtitle: String?
    private let animatesSubtitleAppearance: Bool

    @Environment(\.topNavigationContentAlignment) private var alignment
    @ScaledMetric private var titleSubtitleSpacing = Metrics.titleSubtitleSpacing

    public init(
        title: String,
        subtitle: String? = nil,
        animatesSubtitleAppearance: Bool = true
    ) {
        self.title = title
        self.subtitle = subtitle
        self.animatesSubtitleAppearance = animatesSubtitleAppearance
    }

    public var body: some View {
        VStack(alignment: alignment, spacing: titleSubtitleSpacing) {
            Text(title)
                .font(token: DesignSystem.Font.bodyMediumToken)
                .foregroundStyle(DesignSystem.Color.textPrimary)
                .lineLimit(1)

            if let subtitle {
                Text(subtitle)
                    .font(token: DesignSystem.Font.captionMediumToken)
                    .foregroundStyle(DesignSystem.Color.textSecondary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: frameAlignment)
                    .transition(.opacity)
            } else {
                Color.clear
                    .frame(height: 0)
                    .frame(maxWidth: .infinity)
            }
        }
        .animation(appearanceAnimation, value: subtitle != nil)
    }

    private var frameAlignment: Alignment {
        alignment == .leading ? .leading : .center
    }

    private var appearanceAnimation: Animation? {
        animatesSubtitleAppearance ? .default : nil
    }
}

// MARK: - Actions

/// The bar's trailing actions as a standalone view — native glass group on iOS 26, material pill below it — for
/// screens that lay the bar out themselves and cannot pass `actions:` to the modifier.
public struct TopNavigationActions: View {
    private let actions: [TopNavigation.Action]
    private let hasBackground: Bool

    public init(actions: TopNavigation.Actions, hasBackground: Bool = true) {
        self.actions = actions.values
        self.hasBackground = hasBackground
    }

    public var body: some View {
        if #available(iOS 26.0, *) {
            TopNavigationNativeActionsGroup(actions: actions, hasBackground: hasBackground)
        } else {
            TopNavigationActionsPill(actions: actions, hasBackground: hasBackground)
        }
    }
}

// MARK: - Leading decoration

/// Non-interactive leading content — no button chrome, no hit target. `size` scales with Dynamic Type.
public struct TopNavigationDecoration: View {
    private let image: ImageType

    @ScaledMetric private var side: CGFloat

    public init(image: ImageType, size: CGFloat) {
        self.image = image
        _side = ScaledMetric(wrappedValue: size)
    }

    public var body: some View {
        image.image
            .renderingMode(.template)
            .resizable()
            .frame(width: side, height: side)
            .foregroundStyle(DesignSystem.Color.iconPrimary)
    }
}

// MARK: - Actions pill

struct TopNavigationActionsPill: View {
    let actions: [TopNavigation.Action]
    let hasBackground: Bool

    @ScaledMetric private var iconSide = TopNavigationChromeMetrics.actionIconSide

    var body: some View {
        HStack(spacing: .zero) {
            ForEach(actions.indices, id: \.self) { index in
                button(for: actions[index])
            }
        }
        .background {
            Color.clear
                .tangemMaterialSurface(in: Capsule(), shadow: DesignSystem.Shadow.fallbackButton)
                .opacity(hasBackground ? 1 : 0)
                .animation(.default, value: hasBackground)
                // The actions fill the whole 44 pt height UIKit gives the inline bar below iOS 26, so the surface
                // is inset to keep it off the bar's edges — flush with them it reads as clipped once the bar
                // gets its background on scroll. Insetting the surface rather than the actions keeps hit targets.
                .padding(.vertical, Metrics.surfaceVerticalInset)
        }
    }

    @ViewBuilder
    private func button(for action: TopNavigation.Action) -> some View {
        switch action.content {
        case .icon:
            TopNavigationBarButton(action: action, iconSide: iconSide)
                .frame(width: Metrics.actionSide, height: Metrics.actionSide)
                .contentShape(.rect)
        case .title:
            TopNavigationActionButton(action: action)
        }
    }
}

// MARK: - Native actions group (iOS 26)

@available(iOS 26.0, *)
struct TopNavigationNativeActionsGroup: View {
    let actions: [TopNavigation.Action]
    let hasBackground: Bool

    @ScaledMetric private var iconSide = TopNavigationChromeMetrics.actionIconSide

    var body: some View {
        HStack(spacing: .zero) {
            ForEach(actions.indices, id: \.self) { index in
                button(for: actions[index])
            }
        }
        // The capsule hugs its content, so without this the glyphs of a multi-action bar sit flush against
        // its ends. A single action stays a 1:1 square — the extra width would stretch its circle into an oval.
        .padding(.horizontal, actions.count > 1 ? Metrics.capsuleEndPadding : .zero)
        .glassEffect(hasBackground ? .regular.interactive() : .identity, in: .capsule)
        .glassEffectTransition(.materialize)
        .animation(.default, value: hasBackground)
    }

    @ViewBuilder
    private func button(for action: TopNavigation.Action) -> some View {
        switch action.content {
        case .icon:
            TopNavigationBarButton(action: action, iconSide: iconSide)
                .frame(width: Metrics.actionSide, height: Metrics.actionSide)
                .contentShape(.rect)
        case .title:
            TopNavigationBarButton(action: action)
        }
    }
}

// MARK: - Circular chrome button

struct TopNavigationCircleButton: View {
    let action: TopNavigation.Action

    var body: some View {
        TopNavigationActionButton(action: action)
            .tangemMaterialSurface(in: Circle(), interactive: true, shadow: DesignSystem.Shadow.fallbackButton)
    }
}

// MARK: - Bar button

struct TopNavigationBarButton: View {
    let action: TopNavigation.Action
    /// Icons are drawn at their asset's own size unless a side is given — the actions group sets one so its
    /// glyphs match the bar that shipped, while leading and closing chrome keeps its asset size.
    var iconSide: CGFloat?

    var body: some View {
        control
            .tint(DesignSystem.Color.textPrimary)
            .ifLet(action.accessibilityLabel) { view, label in
                view.accessibilityLabel(Text(label))
            }
            .accessibilityIdentifier(action.accessibilityIdentifier)
    }

    @ViewBuilder
    private var control: some View {
        switch action.trigger {
        case .perform(let perform):
            SwiftUI.Button(action: perform) {
                label
            }
        case .menu(let items):
            Menu {
                TopNavigationMenuItems(items: items)
            } label: {
                label
            }
        }
    }

    @ViewBuilder
    private var label: some View {
        switch action.content {
        case .icon(let icon):
            if let iconSide {
                icon.image
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: iconSide, height: iconSide)
            } else {
                icon.image.renderingMode(.template)
            }
        case .title(let title):
            Text(title)
        }
    }
}

// MARK: - Action button

struct TopNavigationActionButton: View {
    let action: TopNavigation.Action

    var body: some View {
        switch action.trigger {
        case .perform(let perform):
            styledButton(perform: perform)
                .accessibilityIdentifier(action.accessibilityIdentifier)
        case .menu(let items):
            Menu {
                TopNavigationMenuItems(items: items)
            } label: {
                // The design-system button is only the menu's face, the menu owns the tap
                styledButton(perform: {})
                    .allowsHitTesting(false)
            }
            .accessibilityIdentifier(action.accessibilityIdentifier)
        }
    }

    private func styledButton(perform: @escaping () -> Void) -> some View {
        button(perform: perform)
            .styleType(.ghost)
            .size(Metrics.chipSize)
    }

    private func button(perform: @escaping () -> Void) -> TangemUI.Button {
        switch action.content {
        case .icon(let icon):
            TangemUI.Button(icon: icon, accessibilityLabel: action.accessibilityLabel, action: perform)
        case .title(let title):
            TangemUI.Button(label: AttributedString(title), accessibilityLabel: action.accessibilityLabel, action: perform)
        }
    }
}

// MARK: - Menu items

struct TopNavigationMenuItems: View {
    let items: [TopNavigation.MenuItem]

    var body: some View {
        ForEach(items.indices, id: \.self) { index in
            let item = items[index]

            SwiftUI.Button(role: item.role, action: item.action) {
                Text(item.title)
            }
            .accessibilityIdentifier(item.accessibilityIdentifier)
        }
    }
}

// MARK: - Chrome metrics

/// Shared so the bar can reason about the width its own items occupy, not just render them.
enum TopNavigationChromeMetrics {
    static let actionSide = TangemUI.Button.Size.x11.height
    static let actionIconSide: CGFloat = .unit(.x7)
    static let nativeCapsuleEndPadding: CGFloat = .unit(.x1)
    static let legacyActionSize: TangemUI.Button.Size = .x9

    /// Largest non-accessibility size: UIKit pins the inline bar height, and accessibility sizes outgrow it.
    static let maxDynamicTypeSize: DynamicTypeSize = .xxxLarge
}

// MARK: - Content alignment

extension EnvironmentValues {
    @Entry var topNavigationContentAlignment: HorizontalAlignment = .center
}

// MARK: - Metrics

private extension TopNavigationTitleContent {
    enum Metrics {
        static let titleSubtitleSpacing: CGFloat = 4
    }
}

private extension TopNavigationActionButton {
    enum Metrics {
        static let chipSize = TopNavigationChromeMetrics.legacyActionSize
    }
}

private extension TopNavigationActionsPill {
    enum Metrics {
        static let actionSide = TopNavigationChromeMetrics.actionSide
        static let surfaceVerticalInset: CGFloat = .unit(.half)
    }
}

@available(iOS 26.0, *)
private extension TopNavigationNativeActionsGroup {
    enum Metrics {
        static let actionSide = TopNavigationChromeMetrics.actionSide
        static let capsuleEndPadding = TopNavigationChromeMetrics.nativeCapsuleEndPadding
    }
}
