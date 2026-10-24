//
//  OfframpBottomBar.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

extension View {
    func offrampBottomBar(
        pinnedBehindKeyboard: Bool = false,
        @ViewBuilder content: () -> some View
    ) -> some View {
        modifier(
            OfframpBottomBarViewModifier(
                pinnedBehindKeyboard: pinnedBehindKeyboard,
                barContent: content()
            )
        )
    }
}

struct OfframpBottomBarViewModifier<BarContent: View>: ViewModifier {
    let pinnedBehindKeyboard: Bool
    let barContent: BarContent

    @State private var keyboardHeight: CGFloat = .zero

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .safeAreaBar(edge: .bottom, spacing: .zero) { pinnedBar { bar } }
                .keyboardHeight(bindTo: $keyboardHeight)
        } else {
            content
                .safeAreaInset(edge: .bottom, spacing: .zero) {
                    pinnedBar {
                        bar.background(alignment: .bottom) {
                            BottomFadeWithBlur(backgroundColor: DesignSystem.Color.bgPrimary)
                        }
                    }
                }
                .keyboardHeight(bindTo: $keyboardHeight)
        }
    }

    private var bar: some View {
        barContent
            .padding(.vertical, OfframpBottomBarMetrics.verticalPadding)
            .padding(.horizontal, OfframpBottomBarMetrics.horizontalPadding)
    }

    private func pinnedBar(@ViewBuilder content: () -> some View) -> some View {
        content()
            .offset(y: keyboardOffset)
            .animation(.keyboard, value: keyboardOffset)
    }

    private var keyboardOffset: CGFloat {
        pinnedBehindKeyboard ? keyboardHeight : .zero
    }
}

// MARK: - Metrics

private enum OfframpBottomBarMetrics {
    static let horizontalPadding: CGFloat = 16
    static let verticalPadding: CGFloat = 8
}

// MARK: - Previews

#Preview {
    ScrollView {
        VStack(spacing: 12) {
            ForEach(0 ..< 20, id: \.self) { index in
                Text("Row \(index + 1)")
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(DesignSystem.Color.bgSecondary)
                    .cornerRadiusContinuous(16)
            }
        }
        .padding(.horizontal, 16)
    }
    .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
    .offrampBottomBar {
        TangemUI.Button(label: "Continue", accessibilityLabel: nil, action: {})
            .size(.x12)
            .styleType(.primary)
            .horizontalLayout(.infinity)
    }
}
