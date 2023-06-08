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
    let action: () -> Void
    let disabled: Bool

    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                icon
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundColor(iconColor)

                if !title.isEmpty {
                    Text(title)
                        .style(Fonts.Bold.subheadline, color: textColor)
                        .lineLimit(1)
                        .padding(.leading, 4)
                        .fixedSize(horizontal: true, vertical: true)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(backgroundColor)
        }
        .disabled(disabled)
        .cornerRadiusContinuous(10)
        .buttonStyle(BorderlessButtonStyle())
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

struct ButtonWithLeadingIcon_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ButtonWithLeadingIcon(title: "Buy", icon: Assets.plusMini.image, action: {}, disabled: false)
            ButtonWithLeadingIcon(title: "Exchange", icon: Assets.exchangeMini.image, action: {}, disabled: true)
            ButtonWithLeadingIcon(title: "Organize tokens", icon: Assets.sliders.image, action: {}, disabled: false)
            ButtonWithLeadingIcon(title: "", icon: Assets.horizontalDots.image, action: {}, disabled: true)
        }
    }
}
