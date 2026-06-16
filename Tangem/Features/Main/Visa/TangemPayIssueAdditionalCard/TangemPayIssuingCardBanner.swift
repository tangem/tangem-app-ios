//
//  TangemPayIssuingCardBanner.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemLocalization

struct TangemPayIssuingCardBanner: View {
    var body: some View {
        HStack(spacing: 12) {
            Assets.Visa.cardInProgress.image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(Localization.tangempayIssuingNewDigitalCardTitle)
                    .style(Fonts.Bold.footnote, color: Colors.Text.primary1)

                Text(Localization.tangempayIssuingYourCardDescription)
                    .style(Fonts.Regular.caption1, color: Colors.Text.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Colors.Background.primary)
        .cornerRadiusContinuous(14)
    }
}
