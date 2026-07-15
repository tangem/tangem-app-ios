//
//  TangemTopNavigationContent.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

// MARK: - Title content

public struct TangemTopNavigationTitleContent: View {
    private let title: String
    private let subtitle: String?
    private let animatesSubtitleAppearance: Bool

    @Environment(\.tangemTopNavigationContentAlignment) private var alignment
    @ScaledMetric private var titleSubtitleSpacing = TangemTopNavigationConstants.titleSubtitleSpacing

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
                SubtitleLabel(subtitle: subtitle, animatesAppearance: animatesSubtitleAppearance)
                    .transition(subtitleTransition)
            }
        }
        .animation(subtitleAnimation, value: subtitle)
    }

    private var subtitleTransition: AnyTransition {
        let slide = AnyTransition.move(edge: .bottom).combined(with: .opacity)

        return .asymmetric(
            insertion: slide.animation(subtitleAnimation),
            removal: slide
        )
    }

    private var subtitleAnimation: Animation? {
        animatesSubtitleAppearance ? .default : nil
    }
}

// MARK: - Subtitle label

private struct SubtitleLabel: View {
    let subtitle: String
    let animatesAppearance: Bool

    var body: some View {
        label
            .id(subtitle)
    }

    @ViewBuilder
    private var label: some View {
        let text = Text(subtitle)
            .font(token: DesignSystem.Font.captionMediumToken)
            .foregroundStyle(DesignSystem.Color.textSecondary)
            .lineLimit(1)

        if !animatesAppearance {
            text.transition(.identity)
        } else if #available(iOS 17.0, *) {
            text.transition(.blurReplace.animation(.smooth(duration: 0.35)))
        } else {
            text.transition(.opacity.animation(.easeInOut(duration: 0.3)))
        }
    }
}

// MARK: - Actions pill

struct TangemTopNavigationActionsPill: View {
    let actions: [TangemTopNavigation.Action]

    var body: some View {
        HStack(spacing: .zero) {
            ForEach(actions.indices, id: \.self) { index in
                TangemTopNavigationActionButton(action: actions[index])
            }
        }
        .tangemMaterialSurface(in: Capsule(), shadow: DesignSystem.Shadow.fallbackButton)
    }
}

// MARK: - Circular chrome button

struct TangemTopNavigationCircleButton: View {
    let action: TangemTopNavigation.Action

    var body: some View {
        TangemTopNavigationActionButton(action: action)
            .tangemMaterialSurface(in: Circle(), interactive: true, shadow: DesignSystem.Shadow.fallbackButton)
    }
}

// MARK: - Native bar button (iOS 26)

@available(iOS 26.0, *)
struct TangemTopNavigationNativeBarButton: View {
    let action: TangemTopNavigation.Action

    var body: some View {
        Button(action: action.action) {
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

struct TangemTopNavigationActionButton: View {
    let action: TangemTopNavigation.Action

    var body: some View {
        button
            .styleType(.ghost)
            .size(TangemTopNavigationConstants.barChipSize)
            .accessibilityIdentifier(action.accessibilityIdentifier)
    }

    private var button: TangemButtonV2 {
        switch action.content {
        case .icon(let icon):
            TangemButtonV2(icon: icon, accessibilityLabel: action.accessibilityLabel, action: action.action)
        case .title(let title):
            TangemButtonV2(label: AttributedString(title), accessibilityLabel: action.accessibilityLabel, action: action.action)
        }
    }
}
