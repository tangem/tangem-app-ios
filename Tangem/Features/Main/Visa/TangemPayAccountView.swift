//
//  TangemPayAccountView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct TangemPayAccountView: View {
    let cardNumber: String
    let balanceString: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Assets.Visa.usa.image
                .resizable()
                .frame(size: .init(bothDimensions: 36))

            VStack(alignment: .leading, spacing: 4) {
                // [REDACTED_TODO_COMMENT]
                Text("Tangem Pay")
                    .style(
                        Fonts.Bold.subheadline,
                        color: Colors.Text.primary1
                    )

                HStack(alignment: .center, spacing: 6) {
                    Assets.Visa.badge.image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 16)

                    Text(cardNumber)
                        .style(
                            Fonts.Regular.caption1,
                            color: Colors.Text.tertiary
                        )
                }
            }

            Spacer()

            VStack {
                Text(balanceString)
                    .style(
                        Fonts.Regular.subheadline,
                        color: Colors.Text.primary1
                    )

                Spacer()
            }
        }
        .defaultRoundedBackground(with: Colors.Background.action, verticalPadding: 14, horizontalPadding: 14)
    }
}
