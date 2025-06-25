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

    public func makeImageView(
        for asset: NFTAsset,
        borderColor: Color,
        cornerRadius: CGFloat? = nil
    ) -> some View {
        let imageAsset = nftChainIconProvider
            .provide(by: asset.id.chain)

        return SquaredOrRectangleImageView(media: NFTAssetMediaExtractor.extractMedia(from: asset))
            .ifLet(cornerRadius) { view, cornerRadius in
                return view.cornerRadius(cornerRadius)
            }
            .networkIconOverlay(imageAsset: imageAsset, borderColor: borderColor)
    }
}
