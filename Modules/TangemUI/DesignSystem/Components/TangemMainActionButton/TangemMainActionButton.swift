//
//  MainActionButton.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

public struct TangemMainActionButton: View {
    private let title: String
    private let icon: Image
    private let buttonState: ButtonState
    private let action: () -> Void

    public init(
        title: String,
        icon: Image,
        buttonState: ButtonState = .normal,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.buttonState = buttonState
        self.action = action
    }

    public var body: some View {
        VStack(spacing: SizeUnit.x2.value) {
            TangemButton(content: .icon(icon), action: action)
                .setSize(.x15)
                .setCornerStyle(.rounded)
                .setStyleType(.secondary)

            Text(title)
                .style(
                    Fonts.Regular.body,
                    color: buttonState.isNormal ? Color.Tangem.Text.Neutral.primary : Color.Tangem.Text.Status.disabled
                )
                .lineLimit(1)
        }
    }
}

#if DEBUG
#Preview("Dark") {
    HStack(spacing: 24) {
        TangemMainActionButton(
            title: "Buy",
            icon: Assets.plusMini.image,
            buttonState: .normal,
            action: { print("Buy tapped") }
        )

        TangemMainActionButton(
            title: "Swap",
            icon: Assets.exchangeMini.image,
            buttonState: .disabled,
            action: { print("Swap tapped") }
        )

        TangemMainActionButton(
            title: "Sell",
            icon: Assets.dollarMini.image,
            buttonState: .normal,
            action: { print("Sell tapped") }
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("Light") {
    HStack(spacing: 24) {
        TangemMainActionButton(
            title: "Buy",
            icon: Assets.plusMini.image,
            buttonState: .normal,
            action: { print("Buy tapped") }
        )

        TangemMainActionButton(
            title: "Swap",
            icon: Assets.exchangeMini.image,
            buttonState: .disabled,
            action: { print("Swap tapped") }
        )

        TangemMainActionButton(
            title: "Sell",
            icon: Assets.dollarMini.image,
            buttonState: .normal,
            action: { print("Sell tapped") }
        )
    }
    .preferredColorScheme(.light)
}
#endif
