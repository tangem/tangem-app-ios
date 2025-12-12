//
//  MarketPriceView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI
import TangemFoundation

struct MarketPriceView: View {
    let currencySymbol: String
    let price: String
    let priceChangeState: TokenPriceChangeView.State
    let miniChartData: LoadingResult<[Double]?, any Error>
    let tapAction: (() -> Void)?

    var body: some View {
        if let tapAction {
            Button(action: tapAction) {
                marketPriceView
            }
            .defaultRoundedBackground()
        } else {
            marketPriceView
                .defaultRoundedBackground()
        }
    }

    private var marketPriceView: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 8) {
                Text(Localization.walletMarketplaceBlockTitle(currencySymbol))
                    .lineLimit(1)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                HStack(spacing: 0) {
                    Text(price)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .style(Fonts.Regular.footnote, color: Colors.Text.primary1)

                    FixedSpacer.horizontal(6)

                    TokenPriceChangeView(state: priceChangeState)
                        .layoutPriority(1)

                    FixedSpacer.horizontal(6)

                    Text(Localization.walletMarketpriceBlockUpdateTime)
                        .lineLimit(1)
                        .layoutPriority(1)
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                }
            }

            Spacer(minLength: 0)

            HStack(spacing: 0) {
                miniChartView
                    .frame(width: 56, height: 24)

                if tapAction != nil {
                    Assets.chevronRightWithOffset24.image
                        .renderingMode(.template)
                        .foregroundColor(Colors.Icon.informative)
                }
            }
        }
    }

    @ViewBuilder
    private var miniChartView: some View {
        switch miniChartData {
        case .loading, .failure:
            SkeletonView()
                .frame(width: 44, height: 12, alignment: .center)
                .cornerRadiusContinuous(4)
        case .success(let values):
            if let values = values {
                LineChartView(
                    color: priceChangeState.signType?.textColor ?? Colors.Text.tertiary,
                    data: values
                )
            } else {
                EmptyView()
            }
        }
    }
}

struct MarketPriceView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            MarketPriceView(currencySymbol: "BTC", price: "5,43 $", priceChangeState: .loaded(signType: .positive, text: "0,08 %"), miniChartData: .loading, tapAction: {})

            MarketPriceView(currencySymbol: "ETH", price: "1 500,33 $", priceChangeState: .loaded(signType: .negative, text: "10,3%"), miniChartData: .success(nil), tapAction: nil)

            MarketPriceView(currencySymbol: "ETH", price: "1 847.90$", priceChangeState: .loaded(signType: .positive, text: "0,08 %"), miniChartData: .failure(""), tapAction: {})

            MarketPriceView(currencySymbol: "ETH", price: "1 234.50$", priceChangeState: .loaded(signType: .neutral, text: "0,0 %"), miniChartData: .loading, tapAction: {})

            MarketPriceView(currencySymbol: "XRP XRP XRP XRP XRP XRP XRP XRP XRP XRP XRP XRP XRP XRP XRP XRP XRP XRP", price: "1 000 000 000 000 000 000 000 000 000 000 000,33 $", priceChangeState: .loaded(signType: .positive, text: "100000000000,33%"), miniChartData: .success([0, 1, 5, 3, 4, 9]), tapAction: {})

            Spacer()
        }
        .frame(maxHeight: .infinity)
        .padding()
        .background(Colors.Background.secondary)
    }
}
