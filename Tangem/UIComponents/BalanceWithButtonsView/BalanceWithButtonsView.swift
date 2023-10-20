//
//  BalanceWithButtonsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

struct BalanceWithButtonsView: View {
    @ObservedObject var viewModel: BalanceWithButtonsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 0) {
                Text(Localization.onboardingBalanceTitle)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                BalanceTitleView(balance: viewModel.fiatBalance, isLoading: viewModel.isLoadingFiatBalance)
                    .padding(.top, 7)

                SensitiveText(viewModel.cryptoBalance)
                    .skeletonable(isShown: viewModel.isLoadingBalance, size: .init(width: 70, height: 12))
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                    .padding(.top, 8)
            }

            ScrollableButtonsView(itemsHorizontalOffset: 14, buttonsInfo: viewModel.buttons)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(Colors.Background.primary)
        .cornerRadiusContinuous(14)
    }
}

struct BalanceWithButtonsView_Previews: PreviewProvider {
    struct BalanceWithButtonsPreview: View {
        private let provider = FakeBalanceWithButtonsInfoProvider()

        var body: some View {
            VStack {
                ForEach(provider.models, id: \.id) { model in
                    BalanceWithButtonsView(viewModel: model)
                }
            }
            .padding(.vertical, 10)
            .background(Colors.Background.secondary)
        }
    }

    static var previews: some View {
        BalanceWithButtonsPreview()
    }
}
