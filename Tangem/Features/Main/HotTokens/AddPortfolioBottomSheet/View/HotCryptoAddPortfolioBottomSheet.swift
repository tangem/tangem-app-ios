//
//  HotCryptoAddPortfolioBottomSheet.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

struct HotCryptoAddToPortfolioBottomSheet: View {
    let info: HotCryptoAddToPortfolioModel
    let action: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text(Localization.commonAddToken)
                .style(Fonts.Bold.body, color: Colors.Text.primary1)

            Text(Localization.hotCryptoAddTokenSubtitle(info.userWalletName))
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                .padding(.bottom, 24)

            if let tokenIconInfo = info.tokenIconInfo {
                TokenIcon(tokenIconInfo: tokenIconInfo, size: .init(bothDimensions: 40))
                    .padding(.bottom, 12)
            }

            Text(info.token.name)
                .style(Fonts.Bold.callout, color: Colors.Text.primary1)
                .padding(.bottom, 6)

            Text(Localization.hotCryptoTokenNetwork(info.tokenNetworkName))
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                .padding(.bottom, 24)

            MainButton(title: Localization.commonAddToPortfolio, icon: .trailing(Assets.tangemIcon), action: action)
        }
        .padding(.init(top: 4, leading: 16, bottom: 6, trailing: 16))
    }
}
