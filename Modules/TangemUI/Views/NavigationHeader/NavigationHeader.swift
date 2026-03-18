//
//  NavigationHeader.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import BlurSwiftUI
import TangemAssets

public struct NavigationHeader<L: View, P: View, T: View>: View {
    private let leadingContent: L
    private let principalContent: P
    private let trailingContent: T

    public init(
        @ViewBuilder leadingContent: () -> L,
        @ViewBuilder principalContent: () -> P,
        @ViewBuilder trailingContent: () -> T
    ) {
        self.leadingContent = leadingContent()
        self.principalContent = principalContent()
        self.trailingContent = trailingContent()
    }

    public var body: some View {
        HStack(spacing: 0) {
            leadingContent
            Spacer(minLength: SizeUnit.x2.value)
            trailingContent
        }
        .overlay(alignment: .center) {
            principalContent
        }
        .padding(.horizontal, .unit(.x4))
        .padding(.top, .unit(.x2))
        .padding(.bottom, .unit(.x3))
        .background(alignment: .top) {
            VariableBlur(direction: .down)
                .dimmingAlpha(.constant(alpha: 0.5))
                .dimmingOvershoot(nil)
                .ignoresSafeArea()
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    VStack {
        NavigationHeader(
            leadingContent: {
                TangemNavigationHeader.LeadingIcon()
            },
            principalContent: {
                LoadableBalanceView(
                    state: .loaded(text: .string("100 $")),
                    style: .init(font: Fonts.Regular.title1, textColor: Colors.Text.primary1),
                    loader: .init(size: CGSize(width: 102, height: 24), cornerRadius: 6),
                    accessibilityIdentifier: .empty
                )
            },
            trailingContent: {
                TangemNavigationHeader.TrailingButtons(
                    secondaryAction: TangemNavigationHeader.ActionInfo(
                        action: {},
                        accessibilityIdentifier: .empty,
                        accessibilityLabel: .empty
                    ),
                    action: TangemNavigationHeader.ActionInfo(
                        action: {},
                        accessibilityIdentifier: .empty,
                        accessibilityLabel: .empty
                    )
                )
            }
        )
        Spacer()
    }
    .background(Color.Tangem.Surface.level1)
}
#endif
