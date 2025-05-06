//
//  SwiftUIView.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import Kingfisher
import TangemUIUtils
import TangemUI
import TangemAssets

struct SquaredOrRectangleImageView: View {
    private let media: NFTMedia?
    private let containerSize: CGSize

    @State private var originalSize: CGSize = .zero
    @State private var loadingFailed = false

    init(media: NFTMedia?, containerSide: CGFloat) {
        self.media = media
        containerSize = .init(bothDimensions: containerSide)
    }

    var body: some View {
        background.overlay(
            image.scaledToFit()
        )
    }

    private var background: some View {
        Colors.Field.focused
            .frame(size: containerSize)
            .cornerRadiusContinuous(Constants.cornerRadius)
    }

    @ViewBuilder
    private var image: some View {
        if let media, !loadingFailed {
            makeMedia(media)
                .if(isSquare) {
                    $0.cornerRadius(Constants.cornerRadius, corners: .allCorners)
                }
        } else {
            downloadFailedPlaceholder
        }
    }

    @ViewBuilder
    private func makeMedia(_ media: NFTMedia) -> some View {
        switch media.kind {
        case .animation:
            buildKFImage(KFAnimatedImage(media.url))
        case .image:
            buildKFImage(KFImage(media.url).resizable())
        case .unknown, .audio, .video:
            downloadFailedPlaceholder
        }
    }

    private var loadingPlaceholder: some View {
        Color.clear
            .skeletonable(isShown: true, width: containerSize.width, height: containerSize.height)
    }

    private var downloadFailedPlaceholder: some View {
        Assets.Nft.assetImagePlaceholder.image
            .resizable()
            .frame(width: containerSize.width / 3, height: containerSize.height / 3)
    }

    private var isSquare: Bool {
        originalSize.width == originalSize.height
    }

    private func buildKFImage<V: KFImageProtocol>(_ image: V) -> some View {
        image
            .cancelOnDisappear(true)
            .placeholder { loadingPlaceholder }
            .fade(duration: 0.3)
            .cacheOriginalImage()
            .onSuccess { r in
                loadingFailed = false
                originalSize = r.image.size
            }
            .onFailure { _ in
                loadingFailed = true
            }
    }
}

private enum Constants {
    static let cornerRadius: CGFloat = 14
}

#if DEBUG
#Preview("Gif") {
    SquaredOrRectangleImageView(
        media: .init(
            kind: .animation,
            url: URL(string: "https://arweave.net/tEidIncXyo5lQ4GYl4uyDYx_qW7g3t4vetp042votww")!
        ),
        containerSide: 200
    )
}

#Preview("Image") {
    SquaredOrRectangleImageView(
        media: .init(
            kind: .animation,
            url: URL(string: "https://cusethejuice.s3.amazonaws.com/cuse-box/assets/compressed-collection.png")!
        ),
        containerSide: 200
    )
}
#endif
