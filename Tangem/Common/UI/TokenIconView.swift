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
    var token: TokenItem
    var size: CGSize = .init(width: 80, height: 80)
    
    var body: some View {
        if let url = token.imageURL {
        #if !CLIP
            KFImage(url)
                .placeholder { token.imageView }
                .setProcessor(DownsamplingImageProcessor(size: size))
                .cacheOriginalImage()
                .scaleFactor(UIScreen.main.scale)
                .resizable()
                .scaledToFit()
                .cornerRadius(5)
        #else
            WebImage(imagePath: url, placeholder: token.imageView.toAnyView())
        #endif
        } else {
            token.imageView
        }
    }
}

extension TokenIconView {
    init(with type: Amount.AmountType, blockchain: Blockchain) {
        if case let .token(token) = type {
            self.token = .token(token, blockchain)
        }
        
        self.token = .blockchain(blockchain)
    }
}

extension TokenItem {
    var iconView: TokenIconView {
        TokenIconView(token: self)
    }
    
    @ViewBuilder fileprivate var imageView: some View {
        switch self {
        case .token(let token, _):
            CircleImageTextView(name: token.name, color: token.color)
        case .blockchain(let blockchain):
            Image(blockchain.iconNameFilled)
                .resizable()
        }
    }
    
    fileprivate var imageURL: URL? {
        switch self {
        case .blockchain(let blockchain):
            return IconsUtils.getBlockchainIconUrl(blockchain).flatMap { URL(string: $0.absoluteString) }
        case .token(let token, _):
            return token.customIconUrl.flatMap{ URL(string: $0) }
        }
    }
}
