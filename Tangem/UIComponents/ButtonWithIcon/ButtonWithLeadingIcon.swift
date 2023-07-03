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
        let colorConfiguration = ButtonWithLeadingIconContentView.ColorConfiguration(
            textColor: textColor,
            iconColor: iconColor,
            backgroundColor: backgroundColor
        )
        ButtonWithLeadingIconContentView(
            title: title,
            icon: icon,
            colorConfiguration: colorConfiguration,
            maintainsIdealSize: true,
            action: action
        )
    }

    @Environment(\.isEnabled) private var isEnabled

    private var textColor: Color {
        isEnabled ? Colors.Text.primary1 : Colors.Text.disabled
    }

    private var iconColor: Color {
        isEnabled ? Colors.Icon.primary1 : Colors.Icon.inactive
    }

    private var backgroundColor: Color {
        isEnabled ? Colors.Button.secondary : Colors.Button.disabled
    }
}

struct FlexySizeButtonWithLeadingIcon: View {
    let title: String
    let icon: Image
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        let colorConfiguration = ButtonWithLeadingIconContentView.ColorConfiguration(
            textColor: isSelected ? Colors.Text.primary1 : Colors.Text.secondary,
            iconColor: isSelected ? Colors.Text.primary1 : Colors.Text.secondary,
            backgroundColor: Colors.Background.primary
        )
        ButtonWithLeadingIconContentView(
            title: title,
            icon: icon,
            colorConfiguration: colorConfiguration,
            maintainsIdealSize: false,
            action: action
        )
    }
}

// MARK: - Private implementation

private struct ButtonWithLeadingIconContentView: View {
    struct ColorConfiguration {
        let textColor: Color
        let iconColor: Color
        let backgroundColor: Color
    }

    let title: String
    let icon: Image
    let colorConfiguration: ColorConfiguration
    let maintainsIdealSize: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                icon
                    .renderingMode(.template)
                    .resizable()
                    .frame(size: .init(bothDimensions: 20))
                    .foregroundColor(colorConfiguration.iconColor)

                if !title.isEmpty {
                    Text(title)
                        .style(Fonts.Bold.subheadline, color: colorConfiguration.textColor)
                        .lineLimit(1)
                        .fixedSize(horizontal: maintainsIdealSize, vertical: maintainsIdealSize)
                }
            }
            .frame(maxWidth: maintainsIdealSize ? nil : .infinity)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(colorConfiguration.backgroundColor)
        }
        .cornerRadiusContinuous(10)
        .buttonStyle(.borderless)
    }
}

// MARK: - Previews

struct ButtonWithLeadingIcon_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray
                .opacity(0.1)
                .ignoresSafeArea()

            VStack {
                FixedSizeButtonWithLeadingIcon(
                    title: "Buy",
                    icon: Assets.plusMini.image
                ) {}

                FixedSizeButtonWithLeadingIcon(
                    title: "Exchange",
                    icon: Assets.exchangeMini.image,
                    action: {}
                )
                .disabled(true)

                FixedSizeButtonWithLeadingIcon(
                    title: "Organize tokens",
                    icon: Assets.sliders.image
                ) {}

                FixedSizeButtonWithLeadingIcon(
                    title: "",
                    icon: Assets.horizontalDots.image,
                    action: {}
                )
                .disabled(true)

                FixedSizeButtonWithLeadingIcon(
                    title: "LongTitle_LongTitle_LongTitle_LongTitle_LongTitle",
                    icon: Assets.infoIconMini.image
                ) {}

                FlexySizeButtonWithLeadingIcon(
                    title: "Buy",
                    icon: Assets.plusMini.image,
                    isSelected: false
                ) {}

                FlexySizeButtonWithLeadingIcon(
                    title: "Exchange",
                    icon: Assets.exchangeMini.image,
                    isSelected: true
                ) {}

                FlexySizeButtonWithLeadingIcon(
                    title: "Organize tokens",
                    icon: Assets.sliders.image,
                    isSelected: false
                ) {}

                FlexySizeButtonWithLeadingIcon(
                    title: "",
                    icon: Assets.horizontalDots.image,
                    isSelected: true
                ) {}

                FlexySizeButtonWithLeadingIcon(
                    title: "LongTitle_LongTitle_LongTitle_LongTitle_LongTitle",
                    icon: Assets.infoIconMini.image,
                    isSelected: false
                ) {}
            }
            .padding(.horizontal)
            .infinityFrame()
        }
    }
}
