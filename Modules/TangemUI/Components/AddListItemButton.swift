//
//  AddActionButton.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

public struct AddListItemButton: View {
    @Environment(\.isEnabled) var isEnabled

    private let text: String
    private let action: () -> Void

    public init(text: String, action: @escaping () -> Void) {
        self.text = text
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                plusIcon

                Text(text)
                    .style(Fonts.Bold.subheadline, color: textAndIconColor)
            }
        }
        .disabled(!isEnabled)
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
        if isEnabled {
            return Colors.Text.accent
        }

        return Colors.Text.disabled
    }

    private var iconBackgroundColor: Color {
        if isEnabled {
            return Colors.Text.accent.opacity(0.1)
        }

        return Colors.Field.focused
    }
}

#if DEBUG
#Preview {
    VStack {
        AddListItemButton(text: "Add account", action: {})
        AddListItemButton(text: "Add account", action: {})
            .disabled(true)
    }
}
#endif
