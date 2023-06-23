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
    private let size: CGSize

    private let networkIconSize: CGSize
    private let networkIconBorderWidth: Double
    private let networkIconOffset: CGSize

    init(viewModel: TokenIconViewModel, sizeSettings: SizeSettings = .tokenItem) {
        self.viewModel = viewModel
        size = sizeSettings.iconSize
        networkIconSize = sizeSettings.networkIconSize
        networkIconBorderWidth = sizeSettings.networkIconBorderWidth
        networkIconOffset = sizeSettings.networkIconOffset
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
            .overlay(networkIcon.offset(networkIconOffset), alignment: .topTrailing)
    }

    @ViewBuilder
    private var networkIcon: some View {
        if let iconName = viewModel.blockchainIconName {
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
        CircleImageTextView(name: viewModel.name, color: Colors.Icon.inactive)
    }
}

extension TokenIconView {
    enum SizeSettings {
        case tokenItem
        case tokenDetails
        case tokenDetailsToolbar
        case receive

        var iconSize: CGSize {
            switch self {
            case .tokenItem: return .init(width: 40, height: 40)
            case .tokenDetails: return .init(bothDimensions: 48)
            case .tokenDetailsToolbar: return .init(bothDimensions: 24)
            case .receive: return .init(width: 80, height: 80)
            }
        }

        var networkIconSize: CGSize {
            switch self {
            case .tokenItem: return .init(width: 16, height: 16)
            case .tokenDetails, .tokenDetailsToolbar: return .zero
            case .receive: return .init(width: 32, height: 32)
            }
        }

        var networkIconBorderWidth: Double {
            switch self {
            case .tokenItem: return 2
            case .tokenDetails, .tokenDetailsToolbar: return 0
            case .receive: return 4
            }
        }

        var networkIconOffset: CGSize {
            switch self {
            case .tokenItem: return .init(width: 4, height: -4)
            case .tokenDetails, .tokenDetailsToolbar: return .zero
            case .receive: return .init(width: 9, height: -9)
            }
        }
    }
}

struct TokenIconView_Preview: PreviewProvider {
    static let viewModel = TokenIconViewModel(tokenItem: .blockchain(.gnosis))
    static let tokenViewModel = TokenIconViewModel(id: "stellar", name: "Stellar", style: .token(Tokens.ethereumFill.name))
    static var previews: some View {
        VStack(spacing: 16) {
            TokenIconView(viewModel: viewModel)

            TokenIconView(viewModel: tokenViewModel, sizeSettings: .tokenDetails)

            TokenIconView(
                viewModel: tokenViewModel,
                sizeSettings: .receive
            )
        }
    }
}
