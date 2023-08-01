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

enum PriceChangeDirection {
    case up
    case same
    case down

    init(_ percentage: Decimal) {
        if percentage.isEqual(to: .zero) {
            self = .same
        } else if percentage > 0 {
            self = .up
        } else {
            self = .down
        }
    }
}

enum CoinViewManageButtonType {
    case add
    case edit
    case info
}

struct PriceChangeView: View {
    let priceChangeDirection: PriceChangeDirection
    let priceChangePercentage: String

    var body: some View {
        #warning("The image from Figma contains hardcoded padding")
        HStack(spacing: 3) {
            Image(systemName: "triangle.fill")
                .resizable()
                .renderingMode(.template)
                .frame(width: 8, height: 6)
                .rotationEffect(priceChangeDirection.iconRotation)
                .foregroundColor(priceChangeDirection.color)

            Text(priceChangePercentage)
                .lineLimit(1)
                .style(Fonts.Regular.footnote, color: priceChangeDirection.color)
        }
    }
}

extension PriceChangeDirection {
    var color: Color {
        switch self {
        case .up:
            return Color(hex: "0099FF")!
        case .same:
            return Color.black
        case .down:
            return Color(hex: "FF3333")!
        }
    }

    var iconRotation: Angle {
        switch self {
        case .up:
            return .zero
        case .same:
            return Angle(degrees: 90)
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
                            .lineLimit(1)

                        Text(symbolFormatted)
                            .lineLimit(1)
                            .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                    HStack(spacing: 4) {
                        Text(model.price)
                            .lineLimit(1)
                            .style(Fonts.Regular.footnote, color: Color(hex: "919191")!)

                        PriceChangeView(priceChangeDirection: model.priceChangeDirection, priceChangePercentage: model.priceChangePercentage)
                    }
                }

                Spacer(minLength: 13)

                LineChartView(
                    color: Color(hex: "#0099FF")!,
                    data: [1, 7, 3, 5, 13]
                )
                .frame(width: 50, height: 37, alignment: .center)

                Spacer(minLength: 43)

                manageButton(for: model.manageType)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isExpanded.toggle()
            }
        }
        .padding(.vertical, 10)
        .animation(nil) // Disable animations on scroll reuse
    }
    
    @ViewBuilder
    func manageButton(for type: CoinViewManageButtonType) -> some View {
        ZStack {
            switch type {
            case .add:
                Button {
                    print("add")
                } label: {
                    Text("Add")
                        .style(Fonts.Bold.caption1, color: Colors.Text.primary2)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Colors.Button.primary)
                        .clipShape(Capsule())
                }
            case .edit:
                Button {
                    print("edit")
                } label: {
                    Text("Edit")
                        .style(Fonts.Bold.caption1, color: Colors.Text.primary2)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Colors.Button.primary)
                        .clipShape(Capsule())
                }
            case .info:
                Image(systemName: "info.circle")
            }
            
            Text("Add")
                .style(Fonts.Bold.caption1, color: Colors.Text.primary2)
                .padding(.horizontal, 12)
                .hidden()
            
            Text("Edit")
                .style(Fonts.Bold.caption1, color: Colors.Text.primary2)
                .padding(.horizontal, 12)
                .hidden()
        }
    }
}

struct CurrencyViewNew_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            CoinView(model: CoinViewModel(
                imageURL: URL(string: "https://raw.githubusercontent.com/trustwallet/assets/master/blockchains/bitcoin/info/logo.png")!,
                name: "Bitcoin",
                symbol: "BTC",
                price: "$23,034.83",
                priceChangeDirection: .up,
                priceChangePercentage: "10.5%",
                manageType: .add
            ))
//            .border(Color.blue.opacity(0.3))

            CoinView(model: CoinViewModel(
                imageURL: URL(string: "https://raw.githubusercontent.com/trustwallet/assets/master/blockchains/ethereum/info/logo.png")!,
                name: "Ethereum",
                symbol: "ETH",
                price: "$1,340.33",
                priceChangeDirection: .down,
                priceChangePercentage: "10.5%",
                manageType: .add
            ))

            CoinView(model: CoinViewModel(
                imageURL: URL(string: "https://raw.githubusercontent.com/trustwallet/assets/master/blockchains/solana/info/logo.png")!,
                name: "Solana",
                symbol: "SOL",
                price: "$33.00",
                priceChangeDirection: .up,
                priceChangePercentage: "1.3%",
                manageType: .add
            ))

            CoinView(model: CoinViewModel(
                imageURL: URL(string: "https://raw.githubusercontent.com/trustwallet/assets/master/blockchains/polygon/info/logo.png")!,
                name: "Polygon",
                symbol: "MATIC",
                price: "$34.83",
                priceChangeDirection: .same,
                priceChangePercentage: "0.0%",
                manageType: .edit
            ))

            CoinView(model: CoinViewModel(
                imageURL: URL(string: "https://raw.githubusercontent.com/trustwallet/assets/master/blockchains/acalaevm/info/logo.png")!,
                name: "Very long token name is very long",
                symbol: "BUS",
                price: "$23,341,324,034.83",
                priceChangeDirection: .up,
                priceChangePercentage: "1,340,340.0%",
                manageType: .info
            ))

            Spacer()
        }
//        .border(Color.blue.opacity(0.3))
        .padding()
    }
}
