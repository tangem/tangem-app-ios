//
//  FloatingSheetNavigationBarView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemAccessibilityIdentifiers

struct FloatingSheetNavigationBarView: View {
    var title: String?
    var subtitle: String?
    var backgroundColor: Color = Colors.Background.tertiary
    var bottomSeparatorLineIsVisible = false
    var backButtonAction: (() -> Void)?
    var closeButtonAction: (() -> Void)?
    var titleAccessibilityIdentifier: String?

    var body: some View {
        ZStack {
            buttons
                .padding(16)

            VStack(spacing: .zero) {
                if let title {
                    Text(title)
                        .style(Fonts.Bold.body, color: Colors.Text.primary1)
                        .ifLet(titleAccessibilityIdentifier) { view, identifier in
                            view.accessibilityIdentifier(identifier)
                        }
                }

                if let subtitle {
                    Text(subtitle)
                        .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 48)
        }
        .background(backgroundColor)
        .overlay(alignment: .bottom) {
            Divider()
                .frame(height: 1)
                .overlay(Colors.Stroke.secondary)
                .opacity(bottomSeparatorLineIsVisible ? 0.3 : 0)
        }
        .contentShape(.rect)
    }

    private var buttons: some View {
        HStack(spacing: .zero) {
            if let backButtonAction {
                NavigationBarButton.back(action: backButtonAction)
            }

            Spacer()

            if let closeButtonAction {
                NavigationBarButton.close(action: closeButtonAction)
            }
        }
    }
}
