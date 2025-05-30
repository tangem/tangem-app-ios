//
//  NFTSendAssetImageViewFactory.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemUIUtils

public struct NFTSendAssetImageViewFactory {
    private let nftChainIconProvider: NFTChainIconProvider

    public init(nftChainIconProvider: NFTChainIconProvider) {
        self.nftChainIconProvider = nftChainIconProvider
    }

    public func makeImageView(for asset: NFTAsset, cornerRadius: CGFloat? = nil) -> some View {
        let image = nftChainIconProvider
            .provide(by: asset.id.chain)
            .image

        return SquaredOrRectangleImageView(media: asset.media)
            .ifLet(cornerRadius) { view, cornerRadius in
                return view.cornerRadius(cornerRadius)
            }
            .networkOverlay(
                image: image,
                offset: .init(width: 6.0, height: -6.0)
            )
    }
}
