//
//  AccountItemView.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct AccountItemView: View {
    @ObservedObject var viewModel: AccountItemViewModel

    var body: some View {
        TwoLineRowWithIcon(
            icon: {
                viewModel.imageData.1
                    .renderingMode(.template)
                    .foregroundStyle(Colors.Icon.inactive)
                    .roundedBackground(with: viewModel.imageData.0, padding: 12)
            },
            primaryLeadingView: {
                Text(viewModel.name)
                    .style(
                        Fonts.Bold.subheadline,
                        color: Colors.Text.primary1
                    )
            },
            primaryTrailingView: {
                LoadableTokenBalanceView(
                    state: viewModel.balanceFiatState,
                    style: .init(font: Fonts.Regular.subheadline, textColor: Colors.Text.primary1),
                    loader: .init(size: .init(width: 40, height: 12))
                )
            },
            secondaryLeadingView: {
                Text(viewModel.tokensCount)
                    .style(
                        Fonts.Bold.caption1,
                        color: Colors.Text.tertiary
                    )
            },
            secondaryTrailingView: {
                TokenPriceChangeView(
                    state: viewModel.priceChangeState,
                    showSkeletonWhenLoading: true
                )
            }
        )
    }
}

#if DEBUG
#Preview {
    ZStack {
        Color.gray
        AccountItemView(viewModel: AccountItemViewModel())
    }
}
#endif
