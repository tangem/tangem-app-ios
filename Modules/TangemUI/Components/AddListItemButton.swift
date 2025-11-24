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
    private let viewData: ViewData

    public init(viewData: ViewData) {
        self.viewData = viewData
    }

    public var body: some View {
        Button(action: viewData.action) {
            HStack(spacing: 12) {
                plusIcon

                Text(viewData.text)
                    .style(Fonts.Bold.subheadline, color: textAndIconColor)

                Spacer()
            }
        }
        .disabled(!viewData.isEnabled)
    }

    private var plusIcon: some View {
        Assets.plusMini
            .image
            .renderingMode(.template)
            .foregroundStyle(textAndIconColor)
            .roundedBackground(
                with: iconBackgroundColor,
                padding: 8,
                radius: 10
            )
    }

    private var textAndIconColor: Color {
        if viewData.isEnabled {
            return Colors.Text.accent
        }

        return Colors.Text.disabled
    }

    private var iconBackgroundColor: Color {
        if viewData.isEnabled {
            return Colors.Text.accent.opacity(0.1)
        }

        return Colors.Field.focused
    }
}

public extension AddListItemButton {
    struct ViewData: Identifiable {
        public var id: String {
            text
        }

        let text: String
        let isEnabled: Bool
        let action: () -> Void

        public init(text: String, isEnabled: Bool = true, action: @escaping () -> Void) {
            self.text = text
            self.isEnabled = isEnabled
            self.action = action
        }

        public static let initial = Self(text: "", action: {})
    }
}

#if DEBUG
#Preview {
    VStack {
        AddListItemButton(viewData: AddListItemButton.ViewData(text: "Add account", action: {}))
        AddListItemButton(viewData: AddListItemButton.ViewData(text: "Add account", isEnabled: false, action: {}))
    }
}
#endif
