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
        KFImage(tokenItem.imageURL)
            .setProcessor(DownsamplingImageProcessor(size: size))
            .placeholder {placeholder }
            .fade(duration: 0.3)
            .forceTransition()
            .cacheOriginalImage()
            .scaleFactor(UIScreen.main.scale)
            .resizable()
            .scaledToFit()
            .cornerRadius(5)
            .frame(size: size)    }
    
    
    @ViewBuilder private var placeholder: some View {
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
            let imagePath = id == "binance-smart-chain" ? "networks" : "coins"
            
            return CurrenciesList.baseURL
                .appendingPathComponent(imagePath)
                .appendingPathComponent("large")
                .appendingPathComponent("\(id).png")
        }
        
        return nil
    }
}
