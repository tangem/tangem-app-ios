//
//  SwappingTokenItemView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct SwappingTokenItemView: View {
    private let viewModel: SwappingTokenItemViewModel

    init(viewModel: SwappingTokenItemViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Button(action: viewModel.itemDidTap) {
            HStack(spacing: 0) {
                HStack(spacing: 12) {
                    IconView(
                        url: viewModel.iconURL,
                        name: viewModel.name,
                        size: CGSize(width: 40, height: 40)
                    )

                    tokenInfoView
                }

                Spacer()

                currencyView
            }
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
    }

    private var tokenInfoView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(viewModel.name)
                .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

            Text(viewModel.symbol)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
        }
    }

    private var currencyView: some View {
        VStack(alignment: .trailing, spacing: 2) {
            if let fiatBalanceFormatted = viewModel.fiatBalanceFormatted {
                Text(fiatBalanceFormatted)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)
            }

            if let balanceFormatted = viewModel.balanceFormatted {
                Text(balanceFormatted)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
            }
        }
    }
}

struct SwappingTokenItemView_Previews: PreviewProvider {
    static let viewModels = [
        SwappingTokenItemViewModel(
            iconURL: nil,
            name: "Bitcoin",
            symbol: "BTC",
            fiatBalance: 1.23415 * 16345,
            balance: 1.23415,
            itemDidTap: {}
        ), SwappingTokenItemViewModel(
            iconURL: nil,
            name: "Ethereum",
            symbol: "ETH",
            fiatBalance: 3.543 * 1341,
            balance: 3.543,
            itemDidTap: {}
        )]

    static var previews: some View {
        ZStack {
            Colors.Background.secondary

            GroupedSection(viewModels) {
                SwappingTokenItemView(viewModel: $0)
            }
            .separatorPadding(68)
        }
    }
}
