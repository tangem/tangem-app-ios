//
//  OnrampSheetHeaderView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemAssets
import TangemUI
import TangemUIUtils

struct OnrampSheetHeaderView: View {
    private let title: String?
    private let subtitle: String?
    private let titleAccessibilityIdentifier: String?
    private let backAction: (() -> Void)?
    private let closeAction: () -> Void

    @ScaledMetric private var titleSubtitleSpacing = Metrics.titleSubtitleSpacing

    init(
        title: String? = nil,
        subtitle: String? = nil,
        titleAccessibilityIdentifier: String? = nil,
        backAction: (() -> Void)? = nil,
        closeAction: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.titleAccessibilityIdentifier = titleAccessibilityIdentifier
        self.backAction = backAction
        self.closeAction = closeAction
    }

    var body: some View {
        HStack(spacing: Metrics.spacing) {
            if let backAction {
                TopNavigationChromeButton(action: .back(accessibilityIdentifier: CommonUIAccessibilityIdentifiers.backButton, action: backAction))
            } else {
                closeButton
                    .hidden()
            }

            titleView
                .frame(maxWidth: .infinity)

            closeButton
        }
        .padding(Metrics.padding)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    @ViewBuilder
    private var titleView: some View {
        if let title {
            VStack(spacing: titleSubtitleSpacing) {
                Text(title)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                    .ifLet(titleAccessibilityIdentifier) { view, identifier in
                        view.accessibilityIdentifier(identifier)
                    }

                if let subtitle {
                    Text(subtitle)
                        .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                }
            }
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
        } else {
            Spacer(minLength: 0)
        }
    }

    private var closeButton: some View {
        TopNavigationChromeButton(action: .close(accessibilityIdentifier: CommonUIAccessibilityIdentifiers.closeButton, action: closeAction))
    }
}

// MARK: - Metrics

private extension OnrampSheetHeaderView {
    enum Metrics {
        static let spacing: CGFloat = 12
        static let padding: CGFloat = 16
        static let titleSubtitleSpacing: CGFloat = 4
    }
}
