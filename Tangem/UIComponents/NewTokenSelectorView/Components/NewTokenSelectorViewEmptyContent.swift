//
//  NewTokenSelectorViewEmptyContent.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

struct NewTokenSelectorViewEmptyContent: View {
    let message: String

    var body: some View {
        VStack(spacing: .zero) {
            Spacer()

            VStack(spacing: 16) {
                Assets.emptyTokenList.image
                    .renderingMode(.template)
                    .foregroundColor(Colors.Icon.inactive)

                Text(message)
                    .multilineTextAlignment(.center)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                    .padding(.horizontal, 50)
            }

            Spacer()
        }
    }
}
