//
//  SuccessToast.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct SuccessToast: View {
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Assets.check.image
                .renderingMode(.template)
                .resizable()
                .frame(width: 12, height: 12)
                .foregroundColor(Colors.Icon.accent)

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
        SendAmountChangedToast(text: "Dummy success tost text")

        Spacer()
    }
}
