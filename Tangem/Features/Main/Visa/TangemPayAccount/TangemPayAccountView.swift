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
import TangemVisa

struct TangemPayAccountView: View {
    let viewModel: TangemPayAccountViewModel

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Assets.Visa.accountAvatar.image
                .resizable()
                .frame(size: .init(bothDimensions: 36))

            VStack(alignment: .leading, spacing: 4) {
                Text(Localization.tangempayPaymentAccount)
                    .style(
                        Fonts.Bold.subheadline,
                        color: Colors.Text.primary1
                    )

                Text(viewModel.state.subtitle)
                    .style(
                        Fonts.Regular.caption1,
                        color: Colors.Text.tertiary
                    )
            }

            Spacer()

            if let balanceText = viewModel.state.balanceText {
                VStack(alignment: .trailing, spacing: 4) {
                    SensitiveText(balanceText)
                        .style(
                            Fonts.Regular.subheadline,
                            color: Colors.Text.primary1
                        )

                    SensitiveText(TangemPayUtilities.usdcTokenItem.currencySymbol)
                        .style(
                            Fonts.Regular.caption1,
                            color: Colors.Text.tertiary
                        )
                }
            }
        }
        .opacity(viewModel.state.isNormal ? 1 : 0.6)
        .defaultRoundedBackground(with: Colors.Background.primary, verticalPadding: 14, horizontalPadding: 14)
        .onTapGesture(perform: viewModel.tapAction)
    }
}
