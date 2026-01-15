//
//  PlusIconView.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

public struct PlusIconView: View {
    private let textAndIconColor: Color
    private let isEnabled: Bool

    public init(textAndIconColor: Color, isEnabled: Bool = true) {
        self.textAndIconColor = textAndIconColor
        self.isEnabled = isEnabled
    }

    public var body: some View {
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

    private var iconBackgroundColor: Color {
        if isEnabled {
            return textAndIconColor.opacity(Constants.iconBackgroundOpacity)
        }

        return Colors.Field.focused
    }
}

// MARK: - Constants

private extension PlusIconView {
    enum Constants {
        static let iconBackgroundOpacity: Double = 0.1
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Default") {
    PlusIconView(textAndIconColor: Colors.Text.accent)
        .padding()
}

#Preview("Disabled") {
    PlusIconView(textAndIconColor: Colors.Text.disabled, isEnabled: false)
        .padding()
}

#Preview("Multiple Variants") {
    VStack(spacing: 16) {
        HStack {
            Text("Enabled:")
            Spacer()
            PlusIconView(textAndIconColor: Colors.Text.accent)
        }

        HStack {
            Text("Disabled:")
            Spacer()
            PlusIconView(textAndIconColor: Colors.Text.disabled, isEnabled: false)
        }
    }
    .padding()
}
#endif // DEBUG
