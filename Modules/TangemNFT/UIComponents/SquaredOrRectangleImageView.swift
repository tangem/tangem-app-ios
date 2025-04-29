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
    private let url: URL?
    private let containerSize: CGSize

    @State private var originalSize: CGSize = .zero
    @State private var loadingFailed = false

    init(url: URL?, containerSide: CGFloat) {
        self.url = url
        containerSize = .init(bothDimensions: containerSide)
    }

    var body: some View {
        background.overlay(image)
    }

    private var background: some View {
        Colors.Field.focused
            .frame(size: containerSize)
            .cornerRadiusContinuous(14)
    }

    @ViewBuilder
    private var image: some View {
        if !loadingFailed {
            kfImage
        } else {
            Assets.Nft.assetImagePlaceholder.image
        }
    }

    private var kfImage: some View {
        KFImage(url)
            .cancelOnDisappear(true)
            .placeholder { placeholder }
            .fade(duration: 0.3)
            .cacheOriginalImage()
            .resizable()
            .onSuccess { r in
                loadingFailed = false
                originalSize = r.image.size
            }
            .onFailure { _ in
                loadingFailed = true
            }
            .if(
                isSquare,
                then: { image in
                    image
                        .cornerRadiusContinuous(14)
                        .frame(size: containerSize)
                },
                else: { image in
                    image
                        .frame(size: sizeForRectangleImage)
                }
            )
            .scaledToFit()
    }

    private var placeholder: some View {
        Color.clear
            .skeletonable(isShown: true, width: containerSize.width, height: containerSize.height)
    }

    private var isSquare: Bool {
        originalSize.width == originalSize.height
    }

    private var sizeForRectangleImage: CGSize {
        guard originalSize != .zero else { return .zero }

        let aspectRatio = originalSize.width / originalSize.height

        return if aspectRatio > 1 {
            CGSize(width: containerSize.width, height: containerSize.height / aspectRatio)
        } else {
            CGSize(width: containerSize.width * aspectRatio, height: containerSize.height)
        }
    }
}

#if DEBUG
#Preview {
    SquaredOrRectangleImageView(
        url: URL(string: "https://cusethejuice.s3.amazonaws.com/cuse-box/assets/compressed-collection.png")!,
        containerSide: 343
    )
}
#endif
