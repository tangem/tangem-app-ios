//
//  StoryActionsView.swift
//  TangemStories
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct StoryActionsView: View {
    let actions: [StoryActionV2]
    let onTap: (StoryActionV2) -> Void

    var body: some View {
        if !actions.isEmpty {
            VStack(spacing: Layout.spacing) {
                ForEach(actions, id: \.id) { action in
                    Button { onTap(action) } label: {
                        Text(action.label)
                            .style(Fonts.BoldStatic.callout, color: foregroundColor(for: action.style))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Layout.verticalPadding)
                    }
                    .background(backgroundColor(for: action.style))
                    .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
                }
            }
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.bottom, Layout.bottomPadding)
        }
    }

    /// Forced-dark stage: `Colors.Button.*` would theme-adapt to brand tint. `.constant` white +
    /// literal `.black` are the intentional non-adaptive fallbacks (no `constantBlack` token today).
    private func foregroundColor(for style: ActionStyle) -> Color {
        style == .primary ? .black : Colors.Text.constantWhite
    }

    private func backgroundColor(for style: ActionStyle) -> Color {
        style == .primary
            ? Colors.Icon.constant
            : Colors.Icon.constant.opacity(Layout.secondaryBackgroundOpacity)
    }

    private enum Layout {
        static let spacing: CGFloat = 10
        static let verticalPadding: CGFloat = 15
        static let horizontalPadding: CGFloat = 16
        static let bottomPadding: CGFloat = 20
        static let cornerRadius: CGFloat = 14
        static let secondaryBackgroundOpacity: Double = 0.16
    }
}
