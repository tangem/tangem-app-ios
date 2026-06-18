//
//  TangemPayClosingCardBanner.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization

struct TangemPayClosingCardBanner: View {
    var body: some View {
        HStack(spacing: 12) {
            Assets.Visa.cardInProgress.image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(Localization.tangempayCardPageClosingBannerTitle)
                    .style(Fonts.Bold.footnote, color: Colors.Text.primary1)

                Text(Localization.tangempayCardPageClosingBannerDescription)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
            }

            Spacer()
        }
        .padding(14)
        .background(Colors.Background.primary)
        .cornerRadiusContinuous(14)
    }
}

#Preview {
    VStack {
        TangemPayReplacingCardBanner()
        TangemPayClosingCardBanner()
        TangemPayIssuingCardBanner()
    }
    .preferredColorScheme(.dark)
}
