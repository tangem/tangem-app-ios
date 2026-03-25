//
//  MarketsHintView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI

struct MarketsHintView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text(Localization.marketsHint)
                .multilineTextAlignment(.center)
                .lineLimit(4)
                .style(Fonts.Regular.footnote, color: Colors.Icon.informative)

            Assets.chevronDown12.image
        }
        .padding(.top, 28)
        .padding(.bottom, 8)
        .frame(width: 162)
    }
}
