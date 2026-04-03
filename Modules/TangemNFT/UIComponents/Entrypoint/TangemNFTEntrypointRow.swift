//
//  TangemNFTEntrypointRow.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils
import TangemUI

public struct TangemNFTEntrypointRow: View {
    @ObservedObject var viewModel: NFTEntrypointViewModel

    // MARK: - Scaled image sizes

    @ScaledSize private var imageContainerSize = CGSize(bothDimensions: 36)
    @ScaledSize private var twoCollectionsImageSize = CGSize(bothDimensions: 24)
    @ScaledSize private var threeCollectionsFirstImageSize = CGSize(bothDimensions: 16)
    @ScaledSize private var threeCollectionsSecondImageSize = CGSize(bothDimensions: 14)
    @ScaledSize private var threeCollectionsThirdImageSize = CGSize(bothDimensions: 20)
    @ScaledSize private var fourCollectionsImageSize = CGSize(bothDimensions: 17)
    @ScaledSize private var dotsImageSize = CGSize(bothDimensions: 9)

    // MARK: - Scaled spacings and offsets

    @ScaledMetric private var pictureYOffset: CGFloat = 3
    @ScaledMetric private var firstTwoImagesVSpacing: CGFloat = 4
    @ScaledMetric private var secondImageXOffset: CGFloat = 6
    @ScaledMetric private var thirdImageXOffset: CGFloat = -3
    @ScaledMetric private var thirdImageYOffset: CGFloat = -3
    @ScaledMetric private var fourCollectionsSpacing: CGFloat = 2
    @ScaledMetric private var imageCornerRadius: CGFloat = .unit(.x1_5)
    @ScaledMetric private var strokeLineWidth: CGFloat = .unit(.half)

    public init(viewModel: NFTEntrypointViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Button(action: viewModel.openCollections) {
            TangemTwoLineRowLayout(
                icon: { collectionsPreview },
                primaryLeading: { titleText },
                secondaryLeading: { subtitleText },
                centeredTrailing: { chevronIcon }
            )
            .padding(.unit(.x3))
            .background(Color.Tangem.Surface.level3)
            .cornerRadiusContinuous(.unit(.x5))
        }
        .buttonStyle(.defaultScaled)
        .onAppear(perform: viewModel.onViewAppear)
    }

    private var titleText: some View {
        Text(viewModel.title)
            .style(TangemRowConstants.Style.Title.font, color: TangemRowConstants.Style.Title.color)
            .lineLimit(1)
    }

    private var subtitleText: some View {
        Text(viewModel.subtitle)
            .style(TangemRowConstants.Style.Subtitle.font, color: TangemRowConstants.Style.Subtitle.color)
            .lineLimit(1)
    }

    private var chevronIcon: some View {
        Assets.Glyphs.chevronRightNew.image
            .renderingMode(.template)
            .foregroundStyle(Color.Tangem.Graphic.Neutral.tertiaryConstant)
    }

    // MARK: - Collection Previews

    @ViewBuilder
    private var collectionsPreview: some View {
        switch viewModel.state {
        case .noCollections:
            Assets.Nft.noNFT.image
                .resizable()
                .frame(size: imageContainerSize)

        case .oneCollection(let media):
            makeImage(media: media, size: imageContainerSize)

        case .twoCollections(let firstMedia, let secondMedia):
            VStack(spacing: .zero) {
                makeImage(media: firstMedia, size: twoCollectionsImageSize)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .offset(y: pictureYOffset)

                makeImage(media: secondMedia, size: twoCollectionsImageSize, shouldStroke: true)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .offset(y: -pictureYOffset)
            }
            .frame(size: imageContainerSize)

        case .threeCollections(let firstMedia, let secondMedia, let thirdMedia):
            VStack(spacing: firstTwoImagesVSpacing) {
                makeImage(media: firstMedia, size: threeCollectionsFirstImageSize)
                makeImage(media: secondMedia, size: threeCollectionsSecondImageSize)
                    .offset(x: secondImageXOffset)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .overlay(alignment: .trailing) {
                makeImage(
                    media: thirdMedia,
                    size: threeCollectionsThirdImageSize,
                    shouldStroke: true
                )
                .offset(
                    x: thirdImageXOffset,
                    y: thirdImageYOffset
                )
            }
            .frame(size: imageContainerSize)

        case .fourCollections(let firstMedia, let secondMedia, let thirdMedia, let fourthMedia):
            VStack(spacing: fourCollectionsSpacing) {
                HStack(spacing: fourCollectionsSpacing) {
                    makeImage(media: firstMedia, size: fourCollectionsImageSize)
                    makeImage(media: secondMedia, size: fourCollectionsImageSize)
                }

                HStack(spacing: fourCollectionsSpacing) {
                    makeImage(media: thirdMedia, size: fourCollectionsImageSize)
                    makeImage(media: fourthMedia, size: fourCollectionsImageSize)
                }
            }
            .frame(size: imageContainerSize)

        case .multipleCollections(let collectionsMedias):
            VStack(spacing: fourCollectionsSpacing) {
                HStack(spacing: fourCollectionsSpacing) {
                    makeImage(media: collectionsMedias[0], size: fourCollectionsImageSize)
                    makeImage(media: collectionsMedias[1], size: fourCollectionsImageSize)
                }

                HStack(spacing: fourCollectionsSpacing) {
                    makeImage(media: collectionsMedias[2], size: fourCollectionsImageSize)
                    dotsImage(size: fourCollectionsImageSize)
                }
            }
            .frame(size: imageContainerSize)
        }
    }

    // MARK: - Image Helpers

    @ViewBuilder
    private func makeImage(media: NFTMedia?, size: CGSize, shouldStroke: Bool = false) -> some View {
        if let media {
            makeMedia(media, size: size)
                .if(shouldStroke) { icon in
                    icon.overlay(
                        RoundedRectangle(cornerRadius: imageCornerRadius)
                            .strokeBorder(Color.Tangem.Surface.level3, lineWidth: strokeLineWidth)
                    )
                }
        } else {
            placeholder(size: size)
        }
    }

    @ViewBuilder
    private func makeMedia(_ media: NFTMedia, size: CGSize) -> some View {
        switch media.kind {
        case .image:
            IconView(
                url: media.url,
                size: size,
                cornerRadius: imageCornerRadius,
                forceKingfisher: true,
                placeholder: {
                    placeholder(size: size)
                }
            )

        case .animation:
            GIFImage(
                url: media.url,
                placeholder: placeholder(size: size)
            )

        case .video, .audio, .unknown:
            placeholder(size: size)
        }
    }

    private func dotsImage(size: CGSize) -> some View {
        RoundedRectangle(cornerRadius: imageCornerRadius)
            .fill(Color.Tangem.Surface.level2)
            .frame(size: size)
            .overlay {
                Assets.horizontalDots.image
                    .resizable()
                    .foregroundStyle(Color.Tangem.Text.Neutral.secondary)
                    .frame(size: dotsImageSize)
            }
    }

    private func placeholder(size: CGSize) -> some View {
        RoundedRectangle(cornerRadius: imageCornerRadius)
            .fill(Color.Tangem.Surface.level2)
            .frame(size: size)
    }
}
