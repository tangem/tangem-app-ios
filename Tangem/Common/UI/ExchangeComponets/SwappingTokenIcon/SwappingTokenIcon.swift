//
//  SwappingTokenIcon.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import Kingfisher

struct SwappingTokenIconViewModel {
    let imageURL: URL
    let networkURL: URL?
    let tokenSymbol: String
    let action: (() -> Void)?
    
    var isTappable: Bool {
        action != nil
    }
    
    init(
        imageURL: URL,
        networkURL: URL? = nil,
        tokenSymbol: String,
        action: (() -> Void)?
    ) {
        self.imageURL = imageURL
        self.networkURL = networkURL
        self.tokenSymbol = tokenSymbol
        self.action = action
    }
}

struct SwappingTokenIconView: View {
    private let viewModel: SwappingTokenIconViewModel

    init(viewModel: SwappingTokenIconViewModel) {
        self.viewModel = viewModel
    }
    
    private let imageSize = CGSize(width: 36, height: 36)
    private let networkIconSize = CGSize(width: 16, height: 16)
    private let chevronIconSize = CGSize(width: 8, height: 8)
    private var chevronYOffset: CGFloat {
        imageSize.height / 2 - chevronIconSize.height / 2
    }
    
    var body: some View {
        Button(action: { viewModel.action?() }) {
            HStack(alignment: .top, spacing: 4) {
                VStack(spacing: 4) {
                    image
                    
                    Text(viewModel.tokenSymbol)
                        .style(Fonts.Bold.footnote, color: Colors.Text.primary1)
                }
                
                Assets.chevronDownMini
                    .resizable()
                    .frame(size: chevronIconSize)
                    .offset(y: chevronYOffset)
                /// We have to keep size of the view same for both cases
                    .opacity(viewModel.isTappable ? 1 : 0)
            }
        }
        .disabled(!viewModel.isTappable)
    }
    
    private var image: some View {
        ZStack(alignment: .topTrailing) {
            icon(url: viewModel.imageURL, size: imageSize)
            
            if let networkIcon = viewModel.networkURL {
                icon(url: networkIcon, size: networkIconSize)
                    .frame(size: networkIconSize)
                    .padding(.all, 1)
                    .background(Colors.Background.primary)
                    .cornerRadius(networkIconSize.height / 2)
                    .offset(x: 6, y: -6)
            }
        }
    }
    
    private func icon(url: URL, size: CGSize) -> some View {
        KFImage(url)
            .setProcessor(DownsamplingImageProcessor(size: size))
            .fade(duration: 0.3)
            .cacheOriginalImage()
            .scaleFactor(UIScreen.main.scale)
            .resizable()
            .scaledToFit()
            .frame(size: size)
    }
}

struct SwappingTokenIcon_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            SwappingTokenIconView(
                viewModel: SwappingTokenIconViewModel(
                    imageURL: TokenIconURLBuilder().iconURL(id: "dai"),
                    networkURL: TokenIconURLBuilder().iconURL(id: "ethereum"),
                    tokenSymbol: "MATIC",
                    action: {}
                )
            )
            
            SwappingTokenIconView(
                viewModel: SwappingTokenIconViewModel(
                    imageURL: TokenIconURLBuilder().iconURL(id: "dai"),
                    networkURL: TokenIconURLBuilder().iconURL(id: "ethereum"),
                    tokenSymbol: "MATIC",
                    action: nil
                )
            )
        }
    }
}
