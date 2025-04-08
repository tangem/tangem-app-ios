//
//  NFTCollectionsCompactView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils
import TangemUI

struct NFTEntrypointView: View {
    @ObservedObject var viewModel: NFTEntrypointViewModel

    var body: some View {
        Button(action: viewModel.openCollections) {
            HStack(spacing: Constants.iconTextsHSpacing) {
                imageContainer
                textsView
                Spacer()
                chevron
                    .hidden(viewModel.state.isLoading)
            }
            .padding(Constants.padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Colors.Background.primary)
            .cornerRadius(Constants.cornerRadius, corners: .allCorners)
        }
    }

    private var imageContainer: some View {
        image
            .frame(size: Constants.ImageContainer.size)
            .skeletonable(
                isShown: viewModel.state.isLoading,
                size: Constants.ImageContainer.size,
                radius: Constants.imageCornerRadius
            )
    }

    @ViewBuilder
    private var image: some View {
        switch viewModel.state {
        case .loading:
            Color.clear
        case .failedToLoad:
            imageForFailedState
        case .loaded(let collectionsState):
            imageForSuccess(collectionsState: collectionsState)
        }
    }

    private var imageForFailedState: some View {
        RoundedRectangle(cornerRadius: Constants.imageCornerRadius)
            .fill(Colors.Field.primary)
            .overlay {
                Assets.failedCloud.image
                    .resizable()
                    .foregroundStyle(Colors.Icon.informative)
                    .frame(size: Constants.Failed.imageSize)
            }
    }

    @ViewBuilder
    private func imageForSuccess(
        collectionsState: NFTEntrypointViewModel.CollectionsViewState
    ) -> some View {
        switch collectionsState {
        case .noCollections:
            Assets.Nft.noNFT.image

        case .oneCollection(let imageURL):
            makeImage(url: imageURL, size: Constants.ImageContainer.size)

        case .twoCollections(let firstCollectionImageURL, let secondCollectionImageURL):
            let size = Constants.TwoCollections.imageSize

            VStack(spacing: .zero) {
                makeImage(url: firstCollectionImageURL, size: size)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .offset(y: Constants.TwoCollections.pictureYOffset)

                makeImage(url: secondCollectionImageURL, size: size, shouldStroke: true)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .offset(y: -Constants.TwoCollections.pictureYOffset)
            }

        case .threeCollections(
            let firstCollectionImageURL,
            let secondCollectionImageURL,
            let thirdCollectionImageURL
        ):
            VStack(spacing: Constants.ThreeCollections.firstTwoImagesVSpacing) {
                makeImage(url: firstCollectionImageURL, size: Constants.ThreeCollections.firstImageSize)
                makeImage(url: secondCollectionImageURL, size: Constants.ThreeCollections.secondImageSize)
                    .offset(x: Constants.ThreeCollections.secondImageXOffset)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .overlay(alignment: .trailing) {
                makeImage(
                    url: thirdCollectionImageURL,
                    size: Constants.ThreeCollections.thirdImageSize,
                    shouldStroke: true
                )
                .offset(
                    x: Constants.ThreeCollections.thirdImageXOffset,
                    y: Constants.ThreeCollections.thirdImageYOffset
                )
            }

        case .fourCollections(
            let firstCollectionImageURL,
            let secondCollectionImageURL,
            let thirdCollectionImageURL,
            let fourthCollectionImageURL
        ):
            let size = Constants.FourCollections.imageSize
            let spacing = Constants.FourCollections.spacing

            VStack(spacing: spacing) {
                HStack(spacing: spacing) {
                    makeImage(url: firstCollectionImageURL, size: size)
                    makeImage(url: secondCollectionImageURL, size: size)
                }

                HStack(spacing: spacing) {
                    makeImage(url: thirdCollectionImageURL, size: size)
                    makeImage(url: fourthCollectionImageURL, size: size)
                }
            }

        case .multipleCollections(let collectionsURLs):
            let size = Constants.MultipleCollections.imageSize
            let spacing = Constants.FourCollections.spacing

            VStack(spacing: spacing) {
                HStack(spacing: spacing) {
                    makeImage(url: collectionsURLs[0], size: size)
                    makeImage(url: collectionsURLs[1], size: size)
                }

                HStack(spacing: spacing) {
                    makeImage(url: collectionsURLs[2], size: size)
                    dotsImage(size: size)
                }
            }
        }
    }

    private var textsView: some View {
        VStack(
            alignment: .leading,
            spacing: viewModel.state.isLoading ? Constants.Texts.loadingInteritemSpacing : Constants.Texts.interitemSpacing
        ) {
            Text(viewModel.title)
                .style(Fonts.Bold.subheadline, color: titleColor)
                .skeletonable(isShown: viewModel.state.isLoading, size: Constants.Skeleton.titleSize)

            Text(viewModel.subtitle)
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                .skeletonable(isShown: viewModel.state.isLoading, size: Constants.Skeleton.subtitleSize)
        }
    }

    private var chevron: some View {
        Assets.chevronRight.image
            .frame(size: Constants.chevronSize)
            .foregroundStyle(Colors.Icon.informative)
    }

    private func makeImage(url: URL, size: CGSize, shouldStroke: Bool = false) -> some View {
        IconView(
            url: url,
            size: size,
            cornerRadius: Constants.imageCornerRadius,
            forceKingfisher: true,
            placeholder: {
                placeholder(size: size)
            }
        )
        .if(shouldStroke) { icon in
            icon.overlay(
                RoundedRectangle(cornerRadius: Constants.imageCornerRadius)
                    .strokeBorder(Colors.Background.primary, lineWidth: Constants.strokeLineWidth)
            )
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

    private var titleColor: Color {
        switch viewModel.state {
        case .loading:
            .clear
        case .failedToLoad:
            Colors.Text.tertiary
        case .loaded:
            Colors.Text.primary1
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

        enum Skeleton {
            static let titleSize: CGSize = .init(width: 112, height: 12)
            static let subtitleSize: CGSize = .init(width: 80, height: 12)
        }

        enum Failed {
            static let imageSize: CGSize = .init(bothDimensions: 20)
        }

        enum Texts {
            static let loadingInteritemSpacing: CGFloat = 9
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
#Preview("Loading") {
    ZStack {
        Colors.Field.primary
        NFTEntrypointView(viewModel: NFTEntrypointViewModel(coordinator: NFTEntrypointCoordintor()))
            .padding(.horizontal, 16)
    }
}

#Preview("Failed") {
    ZStack {
        Colors.Field.primary
        NFTEntrypointView(
            viewModel: NFTEntrypointViewModel(
                initialState: .failedToLoad(error: NSError()),
                coordinator: NFTEntrypointCoordintor()
            )
        )
        .padding(.horizontal, 16)
    }
}

#Preview("No collections") {
    ZStack {
        Colors.Field.primary
        NFTEntrypointView(
            viewModel: NFTEntrypointViewModel(
                initialState: .loaded(.noCollections),
                coordinator: NFTEntrypointCoordintor()
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
                initialState: .loaded(
                    .oneCollection(
                        imageURL: URL(
                            string: "https://cusethejuice.s3.amazonaws.com/cuse-box/assets/compressed-collection.png"
                        )!
                    )
                ),
                coordinator: NFTEntrypointCoordintor()
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
                initialState: .loaded(
                    .twoCollections(
                        firstCollectionImageURL: URL(string: "https://cusethejuice.s3.amazonaws.com/cuse-box/assets/compressed-collection.png")!,
                        secondCollectionImageURL: URL(string: "https://arweave.net/ggUMUDPTxiAq25rxo_PlwGjl947sIn2ypczI7ZefsF4")!
                    )
                ),
                coordinator: NFTEntrypointCoordintor()
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
                initialState: .loaded(
                    .threeCollections(
                        firstCollectionImageURL: URL(string: "https://cusethejuice.s3.amazonaws.com/cuse-box/assets/compressed-collection.png")!,
                        secondCollectionImageURL: URL(string: "https://arweave.net/ggUMUDPTxiAq25rxo_PlwGjl947sIn2ypczI7ZefsF4")!,
                        thirdCollectionImageURL: URL(string: "https://s3.us-east-1.amazonaws.com/brma/sd0SOIeVaqGagko1B4w3")!
                    )
                ),
                coordinator: NFTEntrypointCoordintor()
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
                initialState: .loaded(
                    .fourCollections(
                        firstCollectionImageURL: URL(string: "https://cusethejuice.s3.amazonaws.com/cuse-box/assets/compressed-collection.png")!,
                        secondCollectionImageURL: URL(string: "https://arweave.net/ggUMUDPTxiAq25rxo_PlwGjl947sIn2ypczI7ZefsF4")!,
                        thirdCollectionImageURL: URL(string: "https://s3.us-east-1.amazonaws.com/brma/sd0SOIeVaqGagko1B4w3")!,
                        fourthCollectionImageURL: URL(string: "https://image.nftscan.com/sol/logo/6351b964b3e6b39f3522028ebf82ff1e.png")!
                    )
                ),
                coordinator: NFTEntrypointCoordintor()
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
                initialState: .loaded(
                    .multipleCollections(collectionsURLs: [
                        URL(string: "https://cusethejuice.s3.amazonaws.com/cuse-box/assets/compressed-collection.png")!,
                        URL(string: "https://arweave.net/ggUMUDPTxiAq25rxo_PlwGjl947sIn2ypczI7ZefsF4")!,
                        URL(string: "https://s3.us-east-1.amazonaws.com/brma/sd0SOIeVaqGagko1B4w3")!,
                        URL(string: "https://image.nftscan.com/sol/logo/6351b964b3e6b39f3522028ebf82ff1e.png")!,
                    ])
                ),
                coordinator: NFTEntrypointCoordintor()
            )
        )
        .padding(.horizontal, 16)
    }
}
#endif
