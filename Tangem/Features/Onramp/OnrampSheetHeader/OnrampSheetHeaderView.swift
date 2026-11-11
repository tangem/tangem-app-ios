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
    private let closeAction: () -> Void

    init(title: String? = nil, closeAction: @escaping () -> Void) {
        self.title = title
        self.closeAction = closeAction
    }

    var body: some View {
        HStack(spacing: Metrics.spacing) {
            closeButton
                .hidden()

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
            Text(title)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
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
    }
}
