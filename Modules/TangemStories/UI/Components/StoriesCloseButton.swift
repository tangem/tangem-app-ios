//
//  StoriesCloseButton.swift
//  TangemStories
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemAccessibilityIdentifiers

struct StoriesCloseButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Assets.close.image
                .resizable()
                .frame(width: Layout.iconSize, height: Layout.iconSize)
                .foregroundStyle(Colors.Icon.primary1)
                .frame(width: Layout.buttonSize, height: Layout.buttonSize)
                .background(Colors.Icon.constant.opacity(Layout.backgroundOpacity))
                .clipShape(Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(StoriesAccessibilityIdentifiers.closeButton)
    }

    private enum Layout {
        static let iconSize: CGFloat = 14
        static let buttonSize: CGFloat = 36
        static let backgroundOpacity: Double = 0.18
    }
}
