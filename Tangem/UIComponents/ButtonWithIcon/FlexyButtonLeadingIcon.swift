//
//  FlexyButtonWithLeadingIcon.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct FlexyButtonWithLeadingIcon: View {
    let title: String
    let icon: Image
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
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
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Colors.Button.secondary)
        }
        .cornerRadiusContinuous(10)
        .buttonStyle(BorderlessButtonStyle())
    }
}

struct FlexyButtonWithLeadingIcon_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            FlexyButtonWithLeadingIcon(title: "Buy", icon: Assets.plusMini.image, action: {})
            FlexyButtonWithLeadingIcon(title: "Exchange", icon: Assets.exchangeMini.image, action: {})
            FlexyButtonWithLeadingIcon(title: "Organize tokens", icon: Assets.sliders.image, action: {})
            FlexyButtonWithLeadingIcon(title: "", icon: Assets.horizontalDots.image, action: {})
        }
    }
}
