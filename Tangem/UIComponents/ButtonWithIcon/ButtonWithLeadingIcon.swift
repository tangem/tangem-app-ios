//
//  ButtonWithLeadingIcon.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct ButtonWithLeadingIcon: View {
    let title: String
    let icon: Image
    var foregroundColor = Colors.Text.primary1
    var maintainsIdealSize = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4.0) {
                icon
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundColor(foregroundColor)

                if !title.isEmpty {
                    Text(title)
                        .style(Fonts.Bold.subheadline, color: foregroundColor)
                        .lineLimit(1)
                        .fixedSize(horizontal: maintainsIdealSize, vertical: maintainsIdealSize)
                }
            }
            .frame(maxWidth: maintainsIdealSize ? nil : .infinity)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Colors.Button.secondary)
        }
        .cornerRadiusContinuous(10)
        .buttonStyle(.borderless)
    }
}

// MARK: - Previews

struct ButtonWithLeadingIcon_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ButtonWithLeadingIcon(
                title: "Buy",
                icon: Assets.plusMini.image
            ) {}

            ButtonWithLeadingIcon(
                title: "Exchange",
                icon: Assets.exchangeMini.image
            ) {}

            ButtonWithLeadingIcon(
                title: "Organize tokens",
                icon: Assets.sliders.image,
                foregroundColor: .red
            ) {}

            ButtonWithLeadingIcon(
                title: "",
                icon: Assets.horizontalDots.image
            ) {}

            ButtonWithLeadingIcon(
                title: "LongTitle_LongTitle_LongTitle_LongTitle_LongTitle",
                icon: Assets.horizontalDots.image,
                foregroundColor: .blue
            ) {}

            ButtonWithLeadingIcon(
                title: "Buy",
                icon: Assets.plusMini.image,
                maintainsIdealSize: false
            ) {}

            ButtonWithLeadingIcon(
                title: "Exchange",
                icon: Assets.exchangeMini.image,
                maintainsIdealSize: false
            ) {}

            ButtonWithLeadingIcon(
                title: "Organize tokens",
                icon: Assets.sliders.image,
                foregroundColor: .red,
                maintainsIdealSize: false
            ) {}

            ButtonWithLeadingIcon(
                title: "",
                icon: Assets.horizontalDots.image,
                maintainsIdealSize: false
            ) {}

            ButtonWithLeadingIcon(
                title: "LongTitle_LongTitle_LongTitle_LongTitle_LongTitle",
                icon: Assets.horizontalDots.image,
                foregroundColor: .blue,
                maintainsIdealSize: false
            ) {}
        }
    }
}
