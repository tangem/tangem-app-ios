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
                    .transition(.opacity)
            } else {
                Color.clear
                    .frame(height: 0)
            }
        }
        .animation(appearanceAnimation, value: subtitle != nil)
    }

    private var appearanceAnimation: Animation? {
        animatesSubtitleAppearance ? .default : nil
    }
}

// MARK: - Actions

/// The bar's trailing actions as a standalone view — for screens that lay the bar out themselves and cannot pass
/// `actions:` to the modifier.
public struct TopNavigationActions: View {
    private let actions: [TopNavigation.Action]
    private let hasBackground: Bool

    public init(actions: TopNavigation.Actions, hasBackground: Bool = true) {
        self.actions = actions.values
        self.hasBackground = hasBackground
    }

    public var body: some View {
        TopNavigationActionsGroup(actions: actions, hasBackground: hasBackground)
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

// MARK: - Actions group

struct TopNavigationActionsGroup: View {
    let actions: [TopNavigation.Action]
    let hasBackground: Bool

    private let size = TopNavigationChromeMetrics.actionButtonSize

    var body: some View {
        materializing(surfacedActions)
    }

    private var surfacedActions: some View {
        HStack(spacing: TopNavigationChromeMetrics.actionSpacing) {
            ForEach(actions.indices, id: \.self) { index in
                TopNavigationActionButton(action: actions[index], size: size)
                    .barHitTarget(size: size)
            }
        }
        .padding(.horizontal, TopNavigationChromeMetrics.capsuleEndPadding)
        .tangemMaterialSurface(
            in: Capsule(),
            isVisible: hasBackground,
            interactive: true,
            shadow: DesignSystem.Shadow.fallbackButton
        )
        .deferringPressFeedbackToGlass()
    }

    @ViewBuilder
    private func materializing(_ content: some View) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffectTransition(.materialize)
        } else {
            content
        }
    }
}

// MARK: - Circular chrome button

struct TopNavigationCircleButton: View {
    let action: TopNavigation.Action

    private let size = TopNavigationChromeMetrics.chromeButtonSize

    var body: some View {
        TopNavigationActionButton(action: action, size: size)
            .tangemMaterialSurface(in: Circle(), interactive: true, shadow: DesignSystem.Shadow.fallbackButton)
            .barHitTarget(size: size, square: true)
            .deferringPressFeedbackToGlass()
    }
}

// MARK: - Action button

struct TopNavigationActionButton: View {
    let action: TopNavigation.Action
    let size: TangemUI.Button.Size

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
            .ifLet(action.accessibilityLabel) { view, label in
                view.accessibilityLabel(Text(label))
            }
            .accessibilityIdentifier(action.accessibilityIdentifier)
        }
    }

    private func styledButton(perform: @escaping () -> Void) -> some View {
        button(perform: perform)
            .styleType(.ghost)
            .size(size)
            .iconSize(TopNavigationChromeMetrics.iconSize)
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

// MARK: - System-surfaced chrome

@available(iOS 26.0, *)
struct TopNavigationSystemChrome: View {
    let actions: [TopNavigation.Action]

    private let size = TopNavigationChromeMetrics.actionButtonSize

    var body: some View {
        VerticalBarAdaptiveStack(spacing: TopNavigationChromeMetrics.actionSpacing) {
            ForEach(actions.indices, id: \.self) { index in
                TopNavigationActionButton(action: actions[index], size: size)
                    .contentShape(.rect)
            }
        }
        .deferringPressFeedbackToGlass()
    }
}

private struct VerticalBarAdaptiveStack<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: Content

    @Environment(\.verticalBarEdge) private var verticalBarEdge

    var body: some View {
        let layout = verticalBarEdge == nil
            ? AnyLayout(HStackLayout(spacing: spacing))
            : AnyLayout(VStackLayout(spacing: spacing))

        layout { content }
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

// MARK: - Hit target

private extension View {
    func barHitTarget(size: TangemUI.Button.Size, square: Bool = false) -> some View {
        let side = TopNavigationChromeMetrics.hitTargetSide(for: size)

        return frame(width: square ? side : nil, height: side)
            .contentShape(.rect)
    }
}

// MARK: - Press feedback

private extension View {
    @ViewBuilder
    func deferringPressFeedbackToGlass() -> some View {
        if #available(iOS 26.0, *) {
            environment(\.buttonPaintsPressOverlay, false)
        } else {
            self
        }
    }
}

// MARK: - Chrome metrics

enum TopNavigationChromeMetrics {
    static let actionButtonSize: TangemUI.Button.Size = .x9
    static let chromeButtonSize: TangemUI.Button.Size = .x11
    static let iconSize: CGFloat = 24
    static let actionSpacing: CGFloat = .unit(.x1)
    static let trailingGroupSpacing: CGFloat = .unit(.x2)
    static let capsuleEndPadding: CGFloat = 4

    static let maxDynamicTypeSize: DynamicTypeSize = .xxxLarge

    static func hitTargetSide(for size: TangemUI.Button.Size) -> CGFloat {
        max(barHeight, size.height)
    }

    private static let barHeight: CGFloat = .unit(.x11)
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
