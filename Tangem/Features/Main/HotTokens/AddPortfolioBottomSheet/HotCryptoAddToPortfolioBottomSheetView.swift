//
//  HotCryptoAddToPortfolioBottomSheetView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI

struct HotCryptoAddToPortfolioBottomSheetView: View {
    let viewModel: HotCryptoAddToPortfolioBottomSheetViewModel

    var body: some View {
        VStack(spacing: 24) {
            BottomSheetHeaderView(
                title: Localization.commonAddToken,
                subtitle: Localization.hotCryptoAddTokenSubtitle(viewModel.userWalletName)
            )
            .subtitleSpacing(0)
            .verticalPadding(0)

            VStack(spacing: 12) {
                if let tokenIconInfo = viewModel.tokenIconInfo {
                    TokenIcon(tokenIconInfo: tokenIconInfo, size: .init(bothDimensions: 40))
                }

                VStack(spacing: 6) {
                    Text(viewModel.token.name)
                        .style(Fonts.Bold.callout, color: Colors.Text.primary1)

                    Text(Localization.hotCryptoTokenNetwork(viewModel.tokenNetworkName))
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                }
            }

            MainButton(
                title: Localization.commonAddToPortfolio,
                icon: viewModel.mainButtonIcon,
                action: viewModel.action
            )
        }
        .padding(.top, 4)
        .padding(.horizontal, 16)
    }
}
