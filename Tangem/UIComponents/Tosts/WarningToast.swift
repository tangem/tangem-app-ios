//
//  WarningToast.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct WarningToast: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Assets.warningIcon.image
                .resizable()
                .frame(width: 16, height: 16)

            Text(text)
                .style(Fonts.Regular.footnote, color: Colors.Text.disabled)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Colors.Icon.secondary)
        .cornerRadiusContinuous(10)
    }
}

#Preview("Figma") {
    VStack {
        WarningToast(text: "Dummy success toast text")

        Spacer()
    }
}
