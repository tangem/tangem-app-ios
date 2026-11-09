//
//  IconWithMessageView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct IconWithMessageView: View {
    private let icon: ImageType
    private let header: Text
    private let description: Text

    init(
        _ icon: ImageType,
        @ViewBuilder header: () -> Text,
        @ViewBuilder description: () -> Text
    ) {
        self.icon = icon
        self.header = header()
        self.description = description()
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            IconWithBackground(icon: icon)
                .foregroundColor(DesignSystem.Color.iconPrimary)

            VStack(alignment: .leading, spacing: 2) {
                header
                    .style(Fonts.Bold.subheadline, color: DesignSystem.Color.textPrimary)

                description
                    .style(Fonts.Regular.footnote, color: DesignSystem.Color.textSecondary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
    }
}

#Preview {
    VStack {
        IconWithMessageView(
            Assets.cryptoCurrencies,
            header: { Text("You") },
            description: {
                Text("Will get ") + Text("10 USDT").foregroundColor(DesignSystem.Color.textPrimary) + Text(" for each wallet bought by your friend on your Tron network address 0x032980ca98fdfc67ab767b")
            }
        )
        IconWithMessageView(
            Assets.discount,
            header: { Text("Your friend") },
            description: {
                Text("Will get a ") + Text("10% discount").foregroundColor(DesignSystem.Color.textPrimary) + Text(" when buying card on tangem.com")
            }
        )
    }
    .padding(16)
}
