//
//  WarningToast.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils
import TangemAssets

public struct WarningToast: View {
    private let text: String

    public init(text: String) {
        self.text = text
    }

    public var body: some View {
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

// MARK: - Previews

#Preview("Figma") {
    VStack {
        WarningToast(text: "Dummy warning toast text")

        Spacer()
    }
}
