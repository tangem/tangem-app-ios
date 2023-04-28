//
//  TokenIconComponent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Kingfisher

struct TokenIconComponent: View {
    let name: String
    let imageURL: URL?
    let blockchainIconName: String?

    var size = CGSize(width: 40, height: 40)
    var networkIconSize = CGSize(width: 14, height: 14)
    var networkIconBorderWidth: Double = 2

    var body: some View {
        KFImage(imageURL)
            .setProcessor(DownsamplingImageProcessor(size: size))
            .placeholder { placeholder }
            .fade(duration: 0.3)
            .cacheOriginalImage()
            .scaleFactor(UIScreen.main.scale)
            .resizable()
            .scaledToFit()
            .cornerRadius(5)
            .frame(size: size)
            .overlay(networkIcon.offset(x: 4, y: -4), alignment: .topTrailing)
    }

    @ViewBuilder
    private var networkIcon: some View {
        if let iconName = blockchainIconName {
            NetworkIcon(
                imageName: iconName,
                isMainIndicatorVisible: false,
                size: networkIconSize
            )
            .background(
                Color.white
                    .clipShape(Circle())
                    .frame(size: networkIconSize + CGSize(width: 2 * networkIconBorderWidth, height: 2 * networkIconBorderWidth))
            )
        }
    }

    @ViewBuilder
    private var placeholder: some View {
        CircleImageTextView(name: name, color: .tangemGrayLight4)
    }
}

struct TokenIconComponent_Preview: PreviewProvider {
    static let coins = [
        (id: "bitcoin", iconName: nil),
        (id: "ethereum", iconName: nil),
        (id: "tether", iconName: "ethereum"),
        (id: "usd-coin", iconName: "ethereum"),
        (id: "matic-network", iconName: "ethereum"),
        (id: "binance-usd", iconName: "ethereum"),
        (id: "shiba-inu", iconName: "ethereum"),
        (id: "tron", iconName: nil),
        (id: "avalanche-2", iconName: nil),
        (id: "dai", iconName: "avalanche"),
        (id: "wrapped-bitcoin", iconName: "avalanche"),
        (id: "uniswap", iconName: "avalanche"),
    ]

    static var previews: some View {
        ScrollView {
            VStack {
                ForEach(coins, id: \.id) { coin in
                    TokenIconComponent(
                        name: coin.id, imageURL: TokenIconURLBuilder(baseURL: CoinsResponse.baseURL).iconURL(id: coin.id, size: .large),
                        blockchainIconName: coin.iconName
                    )
                }
            }
        }
    }
}
