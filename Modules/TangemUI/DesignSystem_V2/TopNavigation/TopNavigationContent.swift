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

// MARK: - Actions pill

struct TopNavigationActionsPill: View {
    let actions: [TopNavigation.Action]

    var body: some View {
        HStack(spacing: .zero) {
            ForEach(actions.indices, id: \.self) { index in
                TopNavigationActionButton(action: actions[index])
            }
        }
        .tangemMaterialSurface(in: Capsule(), shadow: DesignSystem.Shadow.fallbackButton)
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

// MARK: - Native bar button (iOS 26)

@available(iOS 26.0, *)
struct TopNavigationNativeBarButton: View {
    let action: TopNavigation.Action

    var body: some View {
        SwiftUI.Button(action: action.action) {
            label
        }
        .tint(DesignSystem.Color.textPrimary)
        .ifLet(action.accessibilityLabel) { view, label in
            view.accessibilityLabel(Text(label))
        }
        .accessibilityIdentifier(action.accessibilityIdentifier)
    }

    @ViewBuilder
    private var label: some View {
        switch action.content {
        case .icon(let icon):
            icon.image.renderingMode(.template)
        case .title(let title):
            Text(title)
        }
    }
}

// MARK: - Action button

struct TopNavigationActionButton: View {
    let action: TopNavigation.Action

    var body: some View {
        button
            .styleType(.ghost)
            .size(Metrics.chipSize)
            .accessibilityIdentifier(action.accessibilityIdentifier)
    }

    private var button: TangemUI.Button {
        switch action.content {
        case .icon(let icon):
            TangemUI.Button(icon: icon, accessibilityLabel: action.accessibilityLabel, action: action.action)
        case .title(let title):
            TangemUI.Button(label: AttributedString(title), accessibilityLabel: action.accessibilityLabel, action: action.action)
        }
    }
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
        static let chipSize: TangemUI.Button.Size = .x9
    }
}
