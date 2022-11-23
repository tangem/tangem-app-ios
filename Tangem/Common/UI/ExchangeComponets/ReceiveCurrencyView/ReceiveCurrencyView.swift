//
//  ReceiveCurrencyView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct ReceiveCurrencyView: View {
    private let viewModel: ReceiveCurrencyViewModel

    init(viewModel: ReceiveCurrencyViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerLabel

            mainContent
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(Colors.Background.primary)
        .cornerRadius(14)
    }

    private var headerLabel: some View {
        Text("exchange_receive_view_header".localized)
            .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
    }

    @ViewBuilder
    private var mainContent: some View {
        HStack(spacing: 0) {
            switch viewModel.state {
            case .loading:
                loadingContent
            case .loaded:
                currencyContent
            }

            Spacer()

            tokenView
        }
    }

    private var loadingContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            SkeletonView()
                .frame(width: 102, height: 21)
                .cornerRadius(6)

            SkeletonView()
                .frame(width: 40, height: 11)
                .cornerRadius(6)
        }
        .padding(.vertical, 4)
    }

    private var currencyContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.value)
                .style(Fonts.Regular.title1, color: Colors.Text.primary1)
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            Text(viewModel.fiatValue)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
    }

    private var tokenView: some View {
        Button(action: viewModel.didTapTokenView) {
            HStack(spacing: 8) {
                VStack(spacing: 2) {
                    TokenIconView(viewModel: viewModel.tokenIcon)

                    Text(viewModel.tokenName)
                        .style(Fonts.Bold.footnote, color: Colors.Text.primary1)
                }

                Assets.chevronDownMini
                    .resizable()
                    .frame(width: 9, height: 9)
            }
        }
    }
}

struct ReceiveCurrencyView_Preview: PreviewProvider {
    static let viewModel = ReceiveCurrencyViewModel(
        state: .loaded(11412413131.46, fiatValue: 1000.71),
        tokenIcon: .init(tokenItem: .blockchain(.bitcoin(testnet: false)))
    ) {}

    static let loadingViewModel = ReceiveCurrencyViewModel(
        state: .loading,
        tokenIcon: .init(tokenItem: .blockchain(.bitcoin(testnet: false)))
    ) {}

    static var previews: some View {
        ZStack {
            Colors.Background.secondary

            VStack {
                ReceiveCurrencyView(viewModel: viewModel)

                ReceiveCurrencyView(viewModel: loadingViewModel)
            }
            .padding(.horizontal, 16)
        }
    }
}
