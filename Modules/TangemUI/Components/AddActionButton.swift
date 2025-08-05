//
//  SwiftUIView.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

public struct AddActionButton: View {
    private let text: String
    private let action: () -> Void
    private let isDisabled: Bool

    public init(text: String, action: @escaping () -> Void, isDisabled: Bool) {
        self.text = text
        self.action = action
        self.isDisabled = isDisabled
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                plusIcon

                Text(text)
                    .style(Fonts.Bold.subheadline, color: textAndIconColor)
            }
        }
    }

    private var plusIcon: some View {
        Assets.plusMini
            .image
            .renderingMode(.template)
            .foregroundStyle(textAndIconColor)
            .roundedBackground(
                with: iconBackgroundColor,
                padding: 8,
                radius: 8
            )

    }

    private var textAndIconColor: Color {
        if isDisabled {
            return Colors.Text.disabled
        }

        return Colors.Text.accent
    }

    private var iconBackgroundColor: Color {
        if isDisabled {
            return Colors.Field.focused
        }

        return Colors.Text.accent.opacity(0.1)
    }
}

#if DEBUG
#Preview {
    VStack {
        AddActionButton(text: "Add account", action: {}, isDisabled: false)
        AddActionButton(text: "Add account", action: {}, isDisabled: true)
    }
}
 #endif
