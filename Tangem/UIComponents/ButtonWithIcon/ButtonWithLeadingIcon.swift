//
//  ButtonWithLeadingIcon.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct FixedSizeButtonWithLeadingIcon: View {
    let title: String
    let icon: Image
    let action: () -> Void

    var body: some View {
        ButtonWithLeadingIconContentView(
            title: title,
            icon: icon,
            maintainsIdealSize: true,
            action: action
        )
        .foregroundColor(Colors.Text.primary1)
    }
}

struct FlexySizeSelectedButtonWithLeadingIcon: View {
    let title: String
    let icon: Image
    let action: () -> Void

    var body: some View {
        ButtonWithLeadingIconContentView(
            title: title,
            icon: icon,
            maintainsIdealSize: false,
            action: action
        )
        .foregroundColor(Colors.Text.primary1)
    }
}

struct FlexySizeDeselectedButtonWithLeadingIcon: View {
    let title: String
    let icon: Image
    let action: () -> Void

    var body: some View {
        ButtonWithLeadingIconContentView(
            title: title,
            icon: icon,
            maintainsIdealSize: false,
            action: action
        )
        .foregroundColor(Colors.Text.secondary)
    }
}

// MARK: - Private implementation

private struct ButtonWithLeadingIconContentView: View {
    let title: String
    let icon: Image
    let maintainsIdealSize: Bool
    let action: () -> Void
    let disabled: Bool

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                icon
                    .renderingMode(.template)
                    .resizable()
                    .frame(size: .init(bothDimensions: 20))
                    .foregroundColor(iconColor)

                if !title.isEmpty {
                    Text(title)
                        .font(Fonts.Bold.subheadline)
                        .lineLimit(1)
                        .fixedSize(horizontal: maintainsIdealSize, vertical: maintainsIdealSize)
                }
            }
            .frame(maxWidth: maintainsIdealSize ? nil : .infinity)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(backgroundColor)
        }
        .disabled(disabled)
        .cornerRadiusContinuous(10)
        .buttonStyle(.borderless)
    }

    private var textColor: Color {
        disabled ? Colors.Text.disabled : Colors.Text.primary1
    }

    private var iconColor: Color {
        disabled ? Colors.Icon.inactive : Colors.Icon.primary1
    }

    private var backgroundColor: Color {
        disabled ? Colors.Button.disabled : Colors.Button.secondary
    }
}

// MARK: - Previews

struct ButtonWithLeadingIcon_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            FixedSizeButtonWithLeadingIcon(
                title: "Buy",
                icon: Assets.plusMini.image
            ) {}

            FixedSizeButtonWithLeadingIcon(
                title: "Exchange",
                icon: Assets.exchangeMini.image
            ) {}

            FixedSizeButtonWithLeadingIcon(
                title: "Organize tokens",
                icon: Assets.sliders.image
            ) {}

            FixedSizeButtonWithLeadingIcon(
                title: "",
                icon: Assets.horizontalDots.image
            ) {}

            FixedSizeButtonWithLeadingIcon(
                title: "LongTitle_LongTitle_LongTitle_LongTitle_LongTitle",
                icon: Assets.infoIconMini.image
            ) {}

            FlexySizeDeselectedButtonWithLeadingIcon(
                title: "Buy",
                icon: Assets.plusMini.image
            ) {}

            FlexySizeSelectedButtonWithLeadingIcon(
                title: "Exchange",
                icon: Assets.exchangeMini.image
            ) {}

            FlexySizeDeselectedButtonWithLeadingIcon(
                title: "Organize tokens",
                icon: Assets.sliders.image
            ) {}

            FlexySizeSelectedButtonWithLeadingIcon(
                title: "",
                icon: Assets.horizontalDots.image
            ) {}

            FlexySizeDeselectedButtonWithLeadingIcon(
                title: "LongTitle_LongTitle_LongTitle_LongTitle_LongTitle",
                icon: Assets.infoIconMini.image
            ) {}
            ButtonWithLeadingIcon(title: "Buy", icon: Assets.plusMini.image, action: {}, disabled: false)
            ButtonWithLeadingIcon(title: "Exchange", icon: Assets.exchangeMini.image, action: {}, disabled: true)
            ButtonWithLeadingIcon(title: "Organize tokens", icon: Assets.sliders.image, action: {}, disabled: false)
            ButtonWithLeadingIcon(title: "", icon: Assets.horizontalDots.image, action: {}, disabled: true)
        }
    }
}
