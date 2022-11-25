//
//  TokenIconView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Kingfisher
import SwiftUI

struct TokenIconView: View {
    private let viewModel: TokenIconViewModel
    private let size = CGSize(width: 40, height: 40)

    private let networkIconSize = CGSize(width: 16, height: 16)
    private let networkIconBorderWidth: Double = 2

    init(viewModel: TokenIconViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        KFImage(viewModel.imageURL)
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
        if let iconName = viewModel.blockchainIconName {
            NetworkIcon(imageName: iconName,
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
        CircleImageTextView(name: viewModel.name, color: .tangemGrayLight4)
    }
}

struct TokenIconView_Preview: PreviewProvider {
    static let viewModel = TokenIconViewModel(tokenItem: .blockchain(.gnosis))
    static var previews: some View {
        TokenIconView(viewModel: viewModel)
    }
}
