//
//  TangemPayCashbackEmptyGlowBackground.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils
import TangemAssets

struct TangemPayCashbackEmptyGlowBackground: View {
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color(hex: Constants.centerHex, fallback: .clear),
                        DesignSystem.Color.bgBrand.opacity(0.6),
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: Constants.size / 2
                )
            )
            .blur(radius: Constants.blurRadius)
            .offset(y: -Constants.size / 2)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .ignoresSafeArea()
    }
}

private extension TangemPayCashbackEmptyGlowBackground {
    enum Constants {
        static let centerHex = "#7A4A25"

        static let size: CGFloat = 470
        static let blurRadius: CGFloat = 56
    }
}
