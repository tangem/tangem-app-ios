//
//  ReferralPointView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct ReferralPointView: View {
    private let icon: Image
    private let header: Text
    private let description: Text

    init(
        _ icon: Image,
        @ViewBuilder header: () -> Text,
        @ViewBuilder description: () -> Text
    ) {
        self.icon = icon
        self.header = header()
        self.description = description()
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ReferralPointIcon(icon: icon)
                .foregroundColor(Colors.Icon.primary1)

            VStack(alignment: .leading, spacing: 2) {
                header
                    .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                description
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
    }
}

struct ReferralPointView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ReferralPointView(
                Assets.cryptoCurrencies,
                header: { Text("You") },
                description: {
                    Text("Will get ") + Text("10 USDT").foregroundColor(Colors.Text.primary1) + Text(" for each wallet bought by your friend on your Tron network address 0x032980ca98fdfc67ab767b")
                }
            )
            ReferralPointView(
                Assets.discount,
                header: { Text("Your friend") },
                description: {
                    Text("Will get a ") + Text("10% discount").foregroundColor(Colors.Text.primary1) + Text(" when buying card on tangem.com")
                })
        }
        .padding(16)
    }
}
