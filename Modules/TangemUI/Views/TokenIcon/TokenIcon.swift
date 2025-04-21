//
//  TokenIcon.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Kingfisher
import TangemAssets
import TangemFoundation

public struct TokenIcon: View {
    private let tokenIconInfo: TokenIconInfo
    private let size: CGSize
    private var isWithOverlays: Bool
    private var forceKingfisher: Bool

    private var imageURL: URL? { tokenIconInfo.imageURL }
    private var customTokenColor: Color? { tokenIconInfo.customTokenColor }
    private var blockchainIconAsset: ImageType? { tokenIconInfo.blockchainIconAsset }
    private var isCustom: Bool { tokenIconInfo.isCustom }
    private var networkBorderColor: Color { tokenIconInfo.networkBorderColor }

    private let networkIconSize = CGSize(width: 14, height: 14)
    private let networkIconBorderWidth: Double = 2
    private let customTokenIndicatorSize = CGSize(width: 8, height: 8)
    private let customTokenIndicatorBorderWidth: CGFloat = 2
    private let customTokenIconSizeRatio = 0.54

    private var customTokenIndicatorBorderSize: CGSize {
        customTokenIndicatorSize + CGSize(width: 2 * customTokenIndicatorBorderWidth, height: 2 * customTokenIndicatorBorderWidth)
    }

    public var body: some View {
        if let customTokenColor {
            customTokenIcon(background: customTokenColor)
        } else {
            tokenIcon
        }
    }

    private var tokenIcon: some View {
        IconView(url: imageURL, size: size, forceKingfisher: forceKingfisher)
            .overlay(networkIcon, alignment: .topTrailing)
            .overlay(customTokenIndicator, alignment: .bottomTrailing)
    }

    @ViewBuilder
    private var networkIcon: some View {
        if let iconAsset = blockchainIconAsset, isWithOverlays {
            NetworkIcon(
                imageAsset: iconAsset,
                isActive: true,
                isMainIndicatorVisible: false,
                size: networkIconSize
            )
            .background(
                networkBorderColor
                    .clipShape(Circle())
                    .frame(size: networkIconSize + CGSize(width: 2 * networkIconBorderWidth, height: 2 * networkIconBorderWidth))
            )
            .offset(x: 4, y: -4)
        }
    }

    @ViewBuilder
    private var customTokenIndicator: some View {
        if isCustom, isWithOverlays {
            Circle()
                .foregroundColor(Colors.Icon.informative)
                .frame(size: customTokenIndicatorSize)
                .background(
                    Circle()
                        .foregroundColor(Colors.Background.primary)
                        .frame(size: customTokenIndicatorBorderSize)
                )
                .offset(x: 1, y: 1)
        }
    }

    public init(
        tokenIconInfo: TokenIconInfo,
        size: CGSize,
        isWithOverlays: Bool = true,
        forceKingfisher: Bool = true
    ) {
        self.tokenIconInfo = tokenIconInfo
        self.size = size
        self.isWithOverlays = isWithOverlays
        self.forceKingfisher = forceKingfisher
    }

    private func customTokenIcon(background: Color) -> some View {
        customTokenColor
            .clipShape(Circle())
            .overlay(
                Assets.customTokenStar.image
                    .resizable()
                    .frame(
                        width: size.width * customTokenIconSizeRatio,
                        height: size.height * customTokenIconSizeRatio
                    )
            )
            .frame(size: size)
            .overlay(networkIcon, alignment: .topTrailing)
            .overlay(customTokenIndicator, alignment: .bottomTrailing)
    }
}

// MARK: - Previews

#if DEBUG
struct TokenIcon_Preview: PreviewProvider {
    static let coins = [
        (id: "bitcoin", iconAsset: Tokens.bitcoin),
        (id: "ethereum", iconAsset: nil),
        (id: "tether", iconAsset: Tokens.ethereum),
        (id: "usd-coin", iconAsset: Tokens.ethereum),
        (id: "matic-network", iconAsset: Tokens.ethereum),
        (id: "binance-usd", iconAsset: Tokens.ethereum),
        (id: "shiba-inu", iconAsset: Tokens.ethereum),
        (id: "tron", iconAsset: nil),
        (id: "avalanche-2", iconAsset: nil),
        (id: "dai", iconAsset: Tokens.avalanche),
        (id: "wrapped-bitcoin", iconAsset: Tokens.avalanche),
        (id: "uniswap", iconAsset: Tokens.avalanche),
    ]

    static var previews: some View {
        ScrollView {
            VStack {
                ForEach(coins, id: \.id) { coin in
                    TokenIcon(
                        tokenIconInfo: .init(
                            name: "",
                            blockchainIconAsset: coin.iconAsset,
                            imageURL: nil,
                            isCustom: true,
                            customTokenColor: nil
                        ),
                        size: CGSize(width: 40, height: 40)
                    )
                }
            }
            .infinityFrame()
        }
    }
}
#endif // DEBUG
