//
//  MultiWalletTokenItemsEmptyView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemUIUtils
import TangemAssets
import TangemLocalization

struct MultiWalletTokenItemsEmptyView: View {
    var body: some View {
        VStack(spacing: 16) {
            Assets.emptyTokenList.image
                .foregroundColor(Colors.Icon.inactive)

            Text(Localization.mainEmptyTokensListMessage)
                .multilineTextAlignment(.center)
                .style(
                    Fonts.Regular.footnote,
                    color: Colors.Text.tertiary
                )
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 48)
    }
}
