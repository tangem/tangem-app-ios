//
//  SuccessToast.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils
import TangemAssets

public struct SuccessToast: View {
    private let text: String

    public init(text: String) {
        self.text = text
    }

    public var body: some View {
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

// MARK: - Previews

#Preview("Figma") {
    VStack {
        SuccessToast(text: "Dummy success toast text")

        Spacer()
    }
}
