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
            orderButtonView

            Spacer()

            timeIntervalPicker
        }
    }

    private var orderButtonView: some View {
        VStack {
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
        }
    }

    private var timeIntervalPicker: some View {
        VStack {
            Picker("", selection: $viewModel.marketPriceIntervalType) {
                ForEach(viewModel.marketPriceIntervalTypeOptions) {
                    Text($0.description)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}
