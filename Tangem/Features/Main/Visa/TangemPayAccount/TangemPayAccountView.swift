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
import TangemLocalization

struct TangemPayAccountView: View {
    let viewModel: TangemPayAccountViewModel

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Assets.Visa.usa.image
                .resizable()
                .frame(size: .init(bothDimensions: 36))

            VStack(alignment: .leading, spacing: 4) {
                Text(Localization.tangempayTitle)
                    .style(
                        Fonts.Bold.subheadline,
                        color: Colors.Text.primary1
                    )

                HStack(alignment: .center, spacing: 6) {
                    Assets.Visa.badge.image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 16)

                    Text("*" + viewModel.card.cardNumberEnd)
                        .style(
                            Fonts.Regular.caption1,
                            color: Colors.Text.tertiary
                        )
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                SensitiveText("$ " + viewModel.balance.availableBalance.description)
                    .style(
                        Fonts.Regular.subheadline,
                        color: Colors.Text.primary1
                    )

                SensitiveText(viewModel.balance.currency)
                    .style(
                        Fonts.Regular.caption1,
                        color: Colors.Text.tertiary
                    )
            }
        }
        .defaultRoundedBackground(with: Colors.Background.action, verticalPadding: 14, horizontalPadding: 14)
        .onTapGesture(perform: viewModel.tapAction)
    }
}
