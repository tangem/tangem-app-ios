//
//  SwiftUIView.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemFoundation
import TangemUI
import TangemUIUtils
import TangemLocalization
import TangemAssets

public struct NFTAssetDetailsView: View {
    @ObservedObject private var viewModel: NFTAssetDetailsViewModel

    @State private var buttonHeight: CGFloat = 0
    @State private var shouldShowShadow: Bool = true

    @State private var buttonMinY: CGFloat = 0
    @State private var contentMaxY: CGFloat = 0

    private let coordinateSpaceName = "NFTAssetDetailsViewCoordinateSpace"

    public init(viewModel: NFTAssetDetailsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        content
            .padding(.horizontal, Constants.horizontalPadding)
            .navigationTitle(viewModel.name)
            .navigationBarTitleDisplayMode(.inline)
            .background(Colors.Background.secondary)
    }

    private var content: some View {
        ZStack {
            scrollView
            sendButtonContainer
        }
        .coordinateSpace(name: coordinateSpace)
    }

    private var scrollView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 14) {
                SquaredOrRectangleImageView(
                    url: viewModel.imageURL,
                    containerSide: UIScreen.main.bounds.width - Constants.horizontalPadding * 2
                )
                if let header = viewModel.headerState {
                    NFTDetailsHeaderView(state: header)
                }

                if let traits = viewModel.traits {
                    KeyValuePanelView(config: traits)
                }

                if let baseInfo = viewModel.baseInformation {
                    KeyValuePanelView(config: baseInfo)
                }

                Spacer()
                    .frame(height: buttonHeight)
            }
            .readGeometry(\.frame.maxY, inCoordinateSpace: .named(coordinateSpace), bindTo: $contentMaxY)
            .readContentOffset(inCoordinateSpace: .named(coordinateSpace)) { point in
                let contentMaxYDynamic = contentMaxY - point.y + buttonHeight
                shouldShowShadow = contentMaxYDynamic > buttonMinY
            }
        }
    }

    private var sendButtonContainer: some View {
        VStack(spacing: 0) {
            Spacer()
            sendButton(souldAddShadow: shouldShowShadow)
        }
    }

    private func sendButton(souldAddShadow: Bool) -> some View {
        MainButton(title: Localization.commonSend, action: {})
            .if(souldAddShadow) { view in
                view.background(
                    ListFooterOverlayShadowView()
                )
            }
            .readGeometry(inCoordinateSpace: .named(coordinateSpace)) { value in
                buttonHeight = value.frame.height
                buttonMinY = value.frame.minY
            }
    }

    private var coordinateSpace: CoordinateSpace {
        .named(coordinateSpaceName)
    }
}

private extension NFTAssetDetailsView {
    enum Constants {
        static let horizontalPadding: CGFloat = 16
    }
}

#if DEBUG
#Preview {
    NavigationView {
        NFTAssetDetailsView(
            viewModel: NFTAssetDetailsViewModel(
                asset: NFTAsset(
                    assetIdentifier: "0x79D21ca8eE06E149d296a32295A2D8A97E52af52",
                    collectionIdentifier: "0x79D21ca8eE06E149d296a32295A2D8A97E52af52",
                    chain: .solana,
                    contractType: .erc1155,
                    ownerAddress: "0x79D21ca8eE06E149d296a32295A2D8A97E52af52",
                    name: "My awesone asset",
                    description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec ac dictum ligula. Vestibulum placerat imperdiet feugiat. Fusce vestibulum sagittis convallis. Quisque in ante et ipsum auctor mattis eu in velit. Duis at consequat elit. Nam posuere turpis in dolor finibus, a fringilla tortor dictum. Duis at congue risus, ac rhoncus ligula. Vestibulum tincidunt malesuada maximus. Fusce rutrum porta mi ac lobortis.",
                    media: NFTAsset.Media(kind: .image, url: URL(
                        string: "https://cusethejuice.s3.amazonaws.com/cuse-box/assets/compressed-collection.png"
                    )!),
                    rarity: NFTAsset.Rarity(label: "Top 1% rarity", percentage: nil, rank: 115),
                    traits: [
                        NFTAsset.Trait(name: "Tier", value: "Infinite"),
                        NFTAsset.Trait(name: "Phygital toy", value: "None"),
                        NFTAsset.Trait(name: "Accessory", value: "No accessory"),
                        NFTAsset.Trait(name: "Sneakers", value: "Boots"),
                        NFTAsset.Trait(name: "Artist", value: "DJ Dragoon"),
                        NFTAsset.Trait(name: "Artist", value: "DJ Dragoon"),
                        NFTAsset.Trait(name: "Sneakers", value: "Boots"),
                    ]
                ),
                coordinator: nil,
                nftChainNameProviding: NFTChainNameProviderMock()
            )
        )
        .navigationTitle("My awesome asset")
        .navigationBarTitleDisplayMode(.inline)
    }
}
#endif
