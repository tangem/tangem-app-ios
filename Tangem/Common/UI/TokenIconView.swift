//
//  TokenIconView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Kingfisher
import BlockchainSdk
import SwiftUI

struct TokenIconView: View {
    let tokenItem: TokenItem
    var size: CGSize = .init(width: 40, height: 40)

    private let networkIconSize = CGSize(width: 16, height: 16)
    private let networkIconBorderWidth: Double = 2

    var body: some View {
        KFImage(tokenItem.imageURL)
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
        if case let .token(_, blockchain) = tokenItem {
            NetworkIcon(imageName: blockchain.iconNameFilled,
                        isMainIndicatorVisible: false,
                        size: networkIconSize)
                .background(
                    Color.white
                        .clipShape(Circle())
                        .frame(size: networkIconSize + CGSize(width: 2 * networkIconBorderWidth, height: 2 * networkIconBorderWidth))
                )
        }
    }

    @ViewBuilder
    private var placeholder: some View {
        CircleImageTextView(name: tokenItem.name, color: .tangemGrayLight4)
    }
}

extension TokenIconView {
    init(with type: Amount.AmountType, blockchain: Blockchain) {
        if case let .token(token) = type {
            self.tokenItem = .token(token, blockchain)
            return
        }

        self.tokenItem = .blockchain(blockchain)
    }
}

extension TokenItem {
    fileprivate var imageURL: URL? {
        if let id = self.id {
            return CoinsResponse.baseURL
                .appendingPathComponent("coins")
                .appendingPathComponent("large")
                .appendingPathComponent("\(id).png")
        }

        return nil
    }
}
