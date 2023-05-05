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

    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                icon
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundColor(Colors.Icon.primary1)

                if !title.isEmpty {
                    Text(title)
                        .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
                        .lineLimit(1)
                        .padding(.leading, 4)
                        .fixedSize(horizontal: true, vertical: true)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Colors.Button.secondary)
        }
        .cornerRadiusContinuous(10)
        .buttonStyle(BorderlessButtonStyle())
    }
}

struct ButtonWithLeadingIcon_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ButtonWithLeadingIcon(title: "Buy", icon: Assets.plusMini.image, action: {})
            ButtonWithLeadingIcon(title: "Exchange", icon: Assets.exchangeMini.image, action: {})
            ButtonWithLeadingIcon(title: "Organize tokens", icon: Assets.sliders.image, action: {})
            ButtonWithLeadingIcon(title: "", icon: Assets.horizontalDots.image, action: {})
        }
    }
}
