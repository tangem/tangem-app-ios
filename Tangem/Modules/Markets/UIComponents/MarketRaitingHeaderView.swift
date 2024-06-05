//
//  MarketsRaitingHeaderView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct MarketsRaitingHeaderView: View {
    @ObservedObject var viewModel: MarketRaitingHeaderViewModel

    var body: some View {
        HStack {
            Button {
                viewModel.onOrderActionButtonDidTap()
            } label: {
                HStack {
                    Text(viewModel.marketListOrderType.description)
                        .style(Fonts.Bold.footnote, color: Colors.Text.primary1)

                    Assets
                        .chevronDownMini
                        .image
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Colors.Background.secondary)
                )
            }

            Spacer()

            Picker("", selection: $viewModel.marketPriceIntervalType) {
                ForEach(MarketsPriceIntervalType.allCases, id: \.self) {
                    Text($0.rawValue)
                        .style(Fonts.Bold.footnote, color: Colors.Text.primary1)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 152)
        }
    }
}
