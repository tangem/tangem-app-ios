//
//  NFTEntrypointView.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils
import TangemUI
import Kingfisher

public struct NFTEntrypointView: View {
    @ObservedObject var viewModel: NFTEntrypointViewModel

    public init(viewModel: NFTEntrypointViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Button(action: viewModel.openCollections) {
            HStack(spacing: Constants.iconTextsHSpacing) {
                image
                    .frame(size: Constants.ImageContainer.size)
                textsView
                Spacer()
                chevron
            }
            .padding(Constants.padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Colors.Background.primary)
            .cornerRadius(Constants.cornerRadius, corners: .allCorners)
        }
        .buttonStyle(.defaultScaled)
        .onAppear(perform: viewModel.onViewAppear)
    }

    @ViewBuilder
    private var image: some View {
        switch viewModel.state {
        case .noCollections:
            Assets.Nft.noNFT.image

        case .oneCollection(let media):
            makeImage(media: media, size: Constants.ImageContainer.size)

        case .twoCollections(let firstCollectionMedia, let secondCollectionMedia):
            let size = Constants.TwoCollections.imageSize

            VStack(spacing: .zero) {
                makeImage(media: firstCollectionMedia, size: size)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .offset(y: Constants.TwoCollections.pictureYOffset)

                makeImage(media: secondCollectionMedia, size: size, shouldStroke: true)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .offset(y: -Constants.TwoCollections.pictureYOffset)
            }

        case .threeCollections(
            let firstCollectionMedia,
            let secondCollectionMedia,
            let thirdCollectionMedia
        ):
            VStack(spacing: Constants.ThreeCollections.firstTwoImagesVSpacing) {
                makeImage(media: firstCollectionMedia, size: Constants.ThreeCollections.firstImageSize)
                makeImage(media: secondCollectionMedia, size: Constants.ThreeCollections.secondImageSize)
                    .offset(x: Constants.ThreeCollections.secondImageXOffset)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .overlay(alignment: .trailing) {
                makeImage(
                    media: thirdCollectionMedia,
                    size: Constants.ThreeCollections.thirdImageSize,
                    shouldStroke: true
                )
                .offset(
                    x: Constants.ThreeCollections.thirdImageXOffset,
                    y: Constants.ThreeCollections.thirdImageYOffset
                )
            }

        case .fourCollections(
            let firstCollectionMedia,
            let secondCollectionMedia,
            let thirdCollectionMedia,
            let fourthCollectionMedia
        ):
            let size = Constants.FourCollections.imageSize
            let spacing = Constants.FourCollections.spacing

            VStack(spacing: spacing) {
                HStack(spacing: spacing) {
                    makeImage(media: firstCollectionMedia, size: size)
                    makeImage(media: secondCollectionMedia, size: size)
                }

                HStack(spacing: spacing) {
                    makeImage(media: thirdCollectionMedia, size: size)
                    makeImage(media: fourthCollectionMedia, size: size)
                }
            }

        case .multipleCollections(let collectionsMedias):
            let size = Constants.MultipleCollections.imageSize
            let spacing = Constants.FourCollections.spacing

            VStack(spacing: spacing) {
                HStack(spacing: spacing) {
                    makeImage(media: collectionsMedias[0], size: size)
                    makeImage(media: collectionsMedias[1], size: size)
                }

                HStack(spacing: spacing) {
                    makeImage(media: collectionsMedias[2], size: size)
                    dotsImage(size: size)
                }
            }
        }
    }

    private var textsView: some View {
        VStack(alignment: .leading, spacing: Constants.Texts.interitemSpacing) {
            Text(viewModel.title)
                .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

            Text(viewModel.subtitle)
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
        }
    }

    private var chevron: some View {
        Assets.chevronRight.image
            .frame(size: Constants.chevronSize)
            .foregroundStyle(Colors.Icon.informative)
    }

    @ViewBuilder
    private func makeImage(media: NFTMedia?, size: CGSize, shouldStroke: Bool = false) -> some View {
        if let media {
            makeMedia(media, size: size)
                .if(shouldStroke) { icon in
                    icon.overlay(
                        RoundedRectangle(cornerRadius: Constants.imageCornerRadius)
                            .strokeBorder(Colors.Background.primary, lineWidth: Constants.strokeLineWidth)
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
                cornerRadius: Constants.imageCornerRadius,
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
        RoundedRectangle(cornerRadius: Constants.imageCornerRadius)
            .fill(Colors.Field.focused)
            .frame(size: size)
            .overlay {
                Assets.horizontalDots.image
                    .resizable()
                    .foregroundStyle(Colors.Text.secondary)
                    .frame(size: Constants.MultipleCollections.dotsImageSize)
            }
    }

    private func placeholder(size: CGSize) -> some View {
        RoundedRectangle(cornerRadius: Constants.imageCornerRadius)
            .fill(Colors.Field.primary)
            .frame(size: size)
    }
}

extension NFTEntrypointView {
    enum Constants {
        enum ImageContainer {
            static let size: CGSize = .init(bothDimensions: 36)
        }

        enum TwoCollections {
            static let pictureYOffset: CGFloat = 3
            static let imageSize: CGSize = .init(bothDimensions: 24)
        }

        enum ThreeCollections {
            static let firstImageSize: CGSize = .init(bothDimensions: 16)
            static let secondImageSize: CGSize = .init(bothDimensions: 14)
            static let thirdImageSize: CGSize = .init(bothDimensions: 20)
            static let firstTwoImagesVSpacing: CGFloat = 4
            static let secondImageXOffset: CGFloat = 6
            static let thirdImageYOffset: CGFloat = -3
            static let thirdImageXOffset: CGFloat = -3
        }

        enum FourCollections {
            static let imageSize: CGSize = .init(bothDimensions: 17)
            static let spacing: CGFloat = 2
        }

        enum MultipleCollections {
            static let imageSize: CGSize = .init(bothDimensions: 17)
            static let spacing: CGFloat = 2
            static let dotsImageSize: CGSize = .init(bothDimensions: 9)
        }

        enum Failed {
            static let imageSize: CGSize = .init(bothDimensions: 20)
        }

        enum Texts {
            static let interitemSpacing: CGFloat = 2
        }

        static let iconTextsHSpacing: CGFloat = 8
        static let imageCornerRadius: CGFloat = 6
        static let padding: CGFloat = 14
        static let cornerRadius: CGFloat = 14
        static let chevronSize: CGSize = .init(bothDimensions: 24)
        static let strokeLineWidth: CGFloat = 2
    }
}

#if DEBUG
#Preview("No collections") {
    ZStack {
        Colors.Field.primary
        NFTEntrypointView(
            viewModel: NFTEntrypointViewModel(
                nftManager: NFTManagerMock(state: .success(.init(value: []))),
                accountForCollectionsProvider: AccountNFTCollectionProviderMock(),
                navigationContext: NFTNavigationContextMock(),
                analytics: .empty,
                coordinator: nil
            )
        )
        .padding(.horizontal, 16)
    }
}

#Preview("One collection") {
    ZStack {
        Colors.Field.primary
        NFTEntrypointView(
            viewModel: NFTEntrypointViewModel(
                nftManager: NFTManagerMock(
                    state: .success(
                        .init(
                            value: [
                                .init(
                                    collectionIdentifier: "",
                                    chain: .solana,
                                    contractType: .erc1155,
                                    ownerAddress: "",
                                    name: "",
                                    description: "",
                                    media: .init(
                                        kind: .image,
                                        url: URL(string: "https://cusethejuice.s3.amazonaws.com/cuse-box/assets/compressed-collection.png")!
                                    ),
                                    assetsCount: 2,
                                    assetsResult: []
                                ),
                            ]
                        )
                    )
                ),
                accountForCollectionsProvider: AccountNFTCollectionProviderMock(),
                navigationContext: NFTNavigationContextMock(),
                analytics: .empty,
                coordinator: nil
            )
        )
        .padding(.horizontal, 16)
    }
}

#Preview("Two collections") {
    ZStack {
        Colors.Field.primary
        NFTEntrypointView(
            viewModel: NFTEntrypointViewModel(
                nftManager: NFTManagerMock(
                    state: .success(
                        .init(
                            value: (0 ... 1).map {
                                .init(
                                    collectionIdentifier: "\($0)",
                                    chain: .solana,
                                    contractType: .erc1155,
                                    ownerAddress: "",
                                    name: "",
                                    description: "",
                                    media: .init(
                                        kind: .image,
                                        url: URL(string: "https://cusethejuice.s3.amazonaws.com/cuse-box/assets/compressed-collection.png")!
                                    ),
                                    assetsCount: 2,
                                    assetsResult: []
                                )
                            }
                        )
                    )
                ),
                accountForCollectionsProvider: AccountNFTCollectionProviderMock(),
                navigationContext: NFTNavigationContextMock(),
                analytics: .empty,
                coordinator: nil
            )
        )
        .padding(.horizontal, 16)
    }
}

#Preview("Three collections") {
    ZStack {
        Colors.Field.primary
        NFTEntrypointView(
            viewModel: NFTEntrypointViewModel(
                nftManager: NFTManagerMock(
                    state: .success(
                        .init(
                            value: (0 ... 2).map {
                                .init(
                                    collectionIdentifier: "\($0)",
                                    chain: .solana,
                                    contractType: .erc1155,
                                    ownerAddress: "",
                                    name: "",
                                    description: "",
                                    media: .init(
                                        kind: .image,
                                        url: URL(string: "https://cusethejuice.s3.amazonaws.com/cuse-box/assets/compressed-collection.png")!
                                    ),
                                    assetsCount: 2,
                                    assetsResult: []
                                )
                            }
                        )
                    )
                ),
                accountForCollectionsProvider: AccountNFTCollectionProviderMock(),
                navigationContext: NFTNavigationContextMock(),
                analytics: .empty,
                coordinator: nil
            )
        )
        .padding(.horizontal, 16)
    }
}

#Preview("Four collections") {
    ZStack {
        Colors.Field.primary
        NFTEntrypointView(
            viewModel: NFTEntrypointViewModel(
                nftManager: NFTManagerMock(
                    state: .success(
                        .init(
                            value: (0 ... 3).map {
                                .init(
                                    collectionIdentifier: "\($0)",
                                    chain: .solana,
                                    contractType: .erc1155,
                                    ownerAddress: "",
                                    name: "",
                                    description: "",
                                    media: .init(
                                        kind: .image,
                                        url: URL(string: "https://cusethejuice.s3.amazonaws.com/cuse-box/assets/compressed-collection.png")!
                                    ),
                                    assetsCount: 2,
                                    assetsResult: []
                                )
                            }
                        )
                    )
                ),
                accountForCollectionsProvider: AccountNFTCollectionProviderMock(),
                navigationContext: NFTNavigationContextMock(),
                analytics: .empty,
                coordinator: nil
            )
        )
        .padding(.horizontal, 16)
    }
}

#Preview("Multiple collections") {
    ZStack {
        Colors.Field.primary
        NFTEntrypointView(
            viewModel: NFTEntrypointViewModel(
                nftManager: NFTManagerMock(
                    state: .success(
                        .init(
                            value: (0 ... 5).map {
                                .init(
                                    collectionIdentifier: "\($0)",
                                    chain: .solana,
                                    contractType: .erc1155,
                                    ownerAddress: "",
                                    name: "",
                                    description: "",
                                    media: .init(
                                        kind: .image,
                                        url: URL(string: "https://cusethejuice.s3.amazonaws.com/cuse-box/assets/compressed-collection.png")!
                                    ),
                                    assetsCount: 2,
                                    assetsResult: []
                                )
                            }
                        )
                    )
                ),
                accountForCollectionsProvider: AccountNFTCollectionProviderMock(),
                navigationContext: NFTNavigationContextMock(),
                analytics: .empty,
                coordinator: nil
            )
        )
        .padding(.horizontal, 16)
    }
}
#endif
