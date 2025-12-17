//
//  SwiftUIView.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import Kingfisher
import TangemUIUtils
import TangemUI
import TangemAssets
import TangemFoundation

struct SquaredOrRectangleImageView: View {
    private let media: NFTMedia?
    private var cornerRadius = Constants.defaultCornerRadius

    @State private var containerSize: CGSize = .zero
    @State private var originalSize: CGSize = .zero
    @State private var loadingState: LoadingResult<Void, any Error> = .loading

    init(media: NFTMedia?) {
        self.media = media
    }

    var body: some View {
        background
            .overlay(image.scaledToFit())
            .readGeometry(\.frame.width) {
                containerSize = .init(bothDimensions: $0)
            }
    }

    private var background: some View {
        Colors.Field.focused
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .cornerRadiusContinuous(cornerRadius)
    }

    @ViewBuilder
    private var image: some View {
        if let media, loadingState.error == nil {
            makeMedia(media)
                .if(isSquare) {
                    $0.cornerRadius(cornerRadius, corners: .allCorners)
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

    private var downloadFailedPlaceholder: some View {
        Assets.Nft.assetImagePlaceholder.image
            .resizable()
            .renderingMode(.template)
            .foregroundStyle(Colors.Icon.primary1)
            .frame(width: containerSize.width / 3, height: containerSize.height / 3)
    }

    private var isSquare: Bool {
        let diff = abs(originalSize.width - originalSize.height)
        let minSide = min(originalSize.width, originalSize.height)

        guard minSide > 0 else { return false }

        return (diff / minSide) <= Constants.squaringThresholdPercentage
    }

    private func buildKFImage<V: KFImageProtocol>(_ image: V) -> some View {
        image
            .cancelOnDisappear(true)
            .fade(duration: 0.3)
            .cacheOriginalImage()
            .onSuccess { r in
                loadingState = .success(())
                originalSize = r.image.size
            }
            .onFailure {
                loadingState = .failure($0)
            }
            .skeletonable(
                isShown: loadingState.isLoading,
                radius: cornerRadius
            )
    }
}

// MARK: - Constants

extension SquaredOrRectangleImageView {
    enum Constants {
        static let defaultCornerRadius: CGFloat = 14.0
        /// We need this threshold to determine if an image is square or rectangle.
        /// Otherwise difference in 1 px will result in non-rounded corners even though visually image is squared
        static let squaringThresholdPercentage: CGFloat = 0.03
    }
}

// MARK: - Setupable protocol conformance

extension SquaredOrRectangleImageView: Setupable {
    func cornerRadius(_ cornerRadius: CGFloat) -> Self {
        map { $0.cornerRadius = cornerRadius }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Gif") {
    SquaredOrRectangleImageView(
        media: .init(
            kind: .animation,
            url: URL(string: "https://arweave.net/tEidIncXyo5lQ4GYl4uyDYx_qW7g3t4vetp042votww")!
        )
    )
}

#Preview("Image") {
    SquaredOrRectangleImageView(
        media: .init(
            kind: .animation,
            url: URL(string: "https://cusethejuice.s3.amazonaws.com/cuse-box/assets/compressed-collection.png")!
        )
    )
}
#endif
