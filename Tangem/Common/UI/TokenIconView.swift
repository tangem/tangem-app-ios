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
    
    var body: some View {
#if !CLIP
        KFImage(tokenItem.imageURL)
            .setProcessor(DownsamplingImageProcessor(size: size))
            .placeholder { placeholder }
            .fade(duration: 0.3)
            .forceTransition()
            .cacheOriginalImage()
            .scaleFactor(UIScreen.main.scale)
            .resizable()
            .scaledToFit()
            .cornerRadius(5)
            .frame(size: size)
#else
        WebImage(imagePath: url, placeholder: token.imageView.toAnyView())
#endif
    }
    
    @ViewBuilder
    private var placeholder: some View {
        switch tokenItem {
        case .token:
            CircleImageTextView(name: tokenItem.name, color: .tangemGrayLight4)
        case .blockchain:
            NetworkIcon(imageName: tokenItem.blockchain.iconNameFilled, isMainIndicatorVisible: true, size: self.size)
        }
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
        switch self {
        case .blockchain:
            return nil
        case .token(let token, _):
            return token.customIconUrl.flatMap{ URL(string: $0) }
        }
    }
}
