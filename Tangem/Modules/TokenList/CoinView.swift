//
//  CoinView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Kingfisher

extension Colors {
//    static var blueBlue =
}

enum PriceChange {
    case up
    case down

    init(_ percentage: Decimal) {
        if percentage >= 0 {
            self = .up
        } else {
            self = .down
        }
    }
}

struct PriceChangeView: View {
    let priceChange: PriceChange
    let priceChangePercentage: String

    var body: some View {
        #warning("The image from Figma contains hardcoded padding")
        HStack(spacing: 3) {
            Image(systemName: "triangle.fill")
                .resizable()
                .renderingMode(.template)
                .frame(width: 8, height: 6)
                .rotationEffect(priceChange.iconRotation)
                .foregroundColor(priceChange.color)

            Text(priceChangePercentage)
                .style(Fonts.Regular.footnote, color: priceChange.color)
        }
    }
}

extension PriceChange {
    var color: Color {
        switch self {
        case .up:
            return Color(hex: "0099FF")!
        case .down:
            return Color(hex: "FF3333")!
        }
    }

    var iconRotation: Angle {
        switch self {
        case .up:
            return .zero
        case .down:
            return Angle(degrees: 180)
        }
    }
}

struct CoinView: View {
    @ObservedObject var model: CoinViewModel
    var subtitle: String = Localization.currencySubtitleExpanded

    let iconWidth: Double = 46

    @State private var isExpanded = false

    private var symbolFormatted: String { " \(model.symbol)" }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 0) {
                IconView(url: model.imageURL, size: CGSize(width: iconWidth, height: iconWidth), forceKingfisher: true)
                    .padding(.trailing, 14)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Text(model.name)

                        Text(symbolFormatted)
                            .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
//                    .lineLimit(1)
//                    .font(.system(size: 17, weight: .medium, design: .default))
                    .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                    HStack(spacing: 4) {
                        Text("27,456 $")
                            .style(Fonts.Regular.footnote, color: Color(hex: "919191")!)

                        PriceChangeView(priceChange: Bool.random() ? .up : .down, priceChangePercentage: "10%")
                    }
                }

                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isExpanded.toggle()
            }
        }
        .padding(.vertical, 10)
        .animation(nil) // Disable animations on scroll reuse
    }
}

struct CurrencyViewNew_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            CoinView(model: CoinViewModel(
                imageURL: URL(string: "https://raw.githubusercontent.com/trustwallet/assets/master/blockchains/bitcoin/info/logo.png")!,
                name: "Bitcoin",
                symbol: "BTC"
            ))
            .border(Color.blue.opacity(0.3))

            CoinView(model: CoinViewModel(
                imageURL: URL(string: "https://raw.githubusercontent.com/trustwallet/assets/master/blockchains/ethereum/info/logo.png")!,
                name: "Tether",
                symbol: "USDT"
            ))

            CoinView(model: CoinViewModel(
                imageURL: URL(string: "https://raw.githubusercontent.com/trustwallet/assets/master/blockchains/ethereum/info/logo.png")!,
                name: "Babananas United",
                symbol: "BABASDT"
            ))

            CoinView(model: CoinViewModel(
                imageURL: URL(string: "https://raw.githubusercontent.com/trustwallet/assets/master/blockchains/ethereum/info/logo.png")!,
                name: "Binance USD",
                symbol: "BUS"
            ))

            CoinView(model: CoinViewModel(
                imageURL: URL(string: "https://raw.githubusercontent.com/trustwallet/assets/master/blockchains/ethereum/info/logo.png")!,
                name: "Binance USD very-very-long-name",
                symbol: "BUS"
            ))

            Spacer()
        }
        .border(Color.blue.opacity(0.3))
        .padding()
    }
}
