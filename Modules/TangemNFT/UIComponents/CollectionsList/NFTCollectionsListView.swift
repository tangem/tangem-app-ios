//
//  NFTCollectionsListView.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils
import TangemUI
import TangemLocalization

public struct NFTCollectionsListView: View {
    @ObservedObject private var viewModel: NFTCollectionsListViewModel

    @State private var contentHeight: CGFloat = 0
    @State private var buttonHeight: CGFloat = 0
    @State private var shouldShowShadow: Bool = true
    @State private var buttonMinY: CGFloat = 0

    private let coordinateSpaceName = "NFTCollectionsListViewCoordinateSpace"

    public init(viewModel: NFTCollectionsListViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            content

            receiveButtonContainer
        }
        .coordinateSpace(name: coordinateSpaceName)
        .if(viewModel.isSearchable) {
            $0.nftListSearchable(text: $viewModel.searchEntry)
        }
        .navigationTitle(Localization.nftWalletTitle)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 16)
        .background(Colors.Background.secondary)
        .onAppear(perform: viewModel.onViewAppear)
        .scrollDismissesKeyboardCompat(.immediately)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loaded(let collections) where viewModel.isStateEmpty(collections: collections):
            noCollectionsView

        case .loaded(let collections):
            nonEmptyContentView(collections: collections)

        case .loading:
            loadingView

        case .failedToLoad:
            UnableToLoadDataView(isButtonBusy: false, retryButtonAction: { viewModel.update() })
                .infinityFrame()
        }
    }

    private var noCollectionsView: some View {
        VStack(spacing: 0) {
            Assets.Nft.Collections.noCollections.image
                .resizable()
                .frame(size: .init(bothDimensions: UIScreen.main.bounds.width / 6))
                .padding(.bottom, 24)

            noCollectionsTexts
                .padding(.bottom, 56)
        }
        .padding(.horizontal, Constants.EmptyView.horizontalPadding)
    }

    private var noCollectionsTexts: some View {
        VStack(spacing: 8) {
            Text(Localization.nftCollectionsEmptyTitle)
                .style(Fonts.BoldStatic.title3, color: Colors.Text.primary1)
            Text(Localization.nftCollectionsEmptyDescription)
                .style(Fonts.Regular.callout, color: Colors.Text.secondary)
                .multilineTextAlignment(.center)
        }
    }

    @ViewBuilder
    private func nonEmptyContentView(collections: [NFTCollectionDisclosureGroupViewModel]) -> some View {
        if collections.isNotEmpty {
            collectionsContent(from: collections)
        } else {
            emptySearchView
        }
    }

    private var emptySearchView: some View {
        Text(Localization.nftEmptySearch)
            .style(Fonts.Bold.caption1, color: Colors.Text.tertiary)
    }

    private func collectionsContent(from collections: [NFTCollectionDisclosureGroupViewModel]) -> some View {
        ScrollViewReader { scrollViewProxy in
            RefreshableScrollView(onRefresh: viewModel.update(completion:), useNativeRefresh: true) {
                VStack(spacing: 0) {
                    if let notificationViewData = viewModel.loadingTroublesViewData {
                        NFTNotificationView(viewData: notificationViewData)
                            .padding(.bottom, 12)
                    }

                    LazyVStack(spacing: 0.0) {
                        ForEach(collections, id: \.id) { collectionViewModel in
                            NFTCollectionDisclosureGroupView(viewModel: collectionViewModel)
                                .id(collectionViewModel.id)
                        }
                    }
                    .roundedBackground(
                        with: Constants.RoundedBackground.color,
                        verticalPadding: 0.0,
                        horizontalPadding: Constants.RoundedBackground.padding,
                        radius: Constants.RoundedBackground.radius
                    )
                    .readGeometry(\.frame.height, inCoordinateSpace: coordinateSpace, bindTo: $contentHeight)
                    // We need this code to track view's heigh when row expands
                    // .readGeometry only tracks it before list expands
                    .background(
                        GeometryReader { proxy in
                            Color.clear
                                .onChange(of: viewModel.tappedRowID) { rowID in
                                    onCollectionHeightChanged(
                                        geoProxy: proxy,
                                        scrollProxy: scrollViewProxy,
                                        tappedRowID: rowID
                                    )
                                }
                                .onChange(of: viewModel.loadingTroublesViewData) { _ in
                                    onCollectionHeightChanged(geoProxy: proxy)
                                }
                        }
                    )

                    Spacer()
                        .frame(height: buttonHeight + Constants.contentButtonSpacing)
                }
                .readContentOffset(inCoordinateSpace: coordinateSpace) { point in
                    let contentMaxY = contentHeight - point.y - buttonHeight + Constants.contentButtonSpacing
                    shouldShowShadow = contentMaxY > buttonMinY
                }
            }
            .coordinateSpace(name: coordinateSpaceName)
        }
    }

    private var receiveButtonContainer: some View {
        VStack(spacing: 0) {
            Spacer()
            receiveButton(shouldAddShadow: shouldShowShadow)
        }
    }

    private func receiveButton(shouldAddShadow: Bool) -> some View {
        MainButton(title: Localization.nftCollectionsReceive, action: viewModel.onReceiveButtonTap)
            .padding(.bottom, 6)
            .if(shouldAddShadow) { view in
                view.background(
                    ListFooterOverlayShadowView()
                )
            }
            .readGeometry(\.frame, inCoordinateSpace: coordinateSpace) { frame in
                buttonHeight = frame.height
                buttonMinY = frame.minY
            }
    }

    private var loadingView: some View {
        VStack(spacing: 0) {
            LazyVStack(spacing: 14) {
                ForEach(0 ..< 5) { _ in
                    collectionSkeleton
                }
            }
            .roundedBackground(
                with: Constants.RoundedBackground.color,
                padding: Constants.RoundedBackground.padding,
                radius: Constants.RoundedBackground.radius
            )

            Spacer()
        }
    }

    private var collectionSkeleton: some View {
        HStack(spacing: 12) {
            Color.clear
                .frame(size: NFTCollectionRow.Constants.Icon.size)
                .skeletonable(
                    isShown: true,
                    radius: NFTCollectionRow.Constants.Icon.cornerRadius
                )

            VStack(alignment: .leading, spacing: 10) {
                Color.clear
                    .frame(width: 70, height: 12)
                    .skeletonable(isShown: true, radius: 4)

                Color.clear
                    .frame(width: 54, height: 12)
                    .skeletonable(isShown: true, radius: 4)
            }
        }
        .infinityFrame(alignment: .leading)
    }

    private var coordinateSpace: CoordinateSpace {
        .named(coordinateSpaceName)
    }

    private func onCollectionHeightChanged(
        geoProxy: GeometryProxy,
        scrollProxy: ScrollViewProxy? = nil,
        tappedRowID: AnyHashable? = nil
    ) {
        let rect = geoProxy.frame(in: coordinateSpace)
        let offset = -rect.origin.y
        shouldShowShadow = rect.height - offset > buttonMinY

        // We need to scroll to the row after it changes its height
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
                scrollProxy?.scrollTo(tappedRowID, anchor: .top)
            }
        }
    }
}

private extension View {
    func nftListSearchable(text: Binding<String>) -> some View {
        searchable(
            text: text,
            placement: .navigationBarDrawer(displayMode: .always)
        )
    }
}

extension NFTCollectionsListView {
    enum Constants {
        enum EmptyView {
            static let imageSize: CGSize = .init(bothDimensions: 76)

            static let horizontalPadding: CGFloat = 16
            static let buttonHPaddingInsideContainer: CGFloat = 40
        }

        enum RoundedBackground {
            static let color = Colors.Background.action
            static let padding: CGFloat = 14
            static let radius: CGFloat = 14
        }

        static let contentButtonSpacing: CGFloat = 16
    }
}

#if DEBUG
let collections = (0 ... 20).map {
    NFTCollection(
        collectionIdentifier: "some-\($0)",
        chain: .solana,
        contractType: .erc1155,
        ownerAddress: "0x79D21ca8eE06E149d296a32295A2D8A97E52af52",
        name: "My awesome collection - \($0)",
        description: "",
        media: .init(
            kind: .image,
            url: URL(string: "https://cusethejuice.s3.amazonaws.com/cuse-box/assets/compressed-collection.png")!
        ),
        assetsCount: 0,
        assetsResult: .init(
            value: (0 ... 3).map {
                NFTAsset(
                    assetIdentifier: "some-\($0)",
                    assetContractAddress: "",
                    chain: .solana,
                    contractType: .unknown,
                    decimalCount: 0,
                    ownerAddress: "",
                    name: "My asset",
                    description: "",
                    salePrice: .init(last: .init(value: 2), lowest: nil, highest: nil),
                    media: NFTMedia(kind: .image, url: URL(string: "https://cusethejuice.com/cuse-box/assets-cuse-dalle/80.png")!),
                    rarity: nil,
                    traits: []
                )
            }
        )
    )
}

#Preview("Multiple collections") {
    ZStack {
        Colors.Background.secondary
        NFTCollectionsListView(
            viewModel: .init(
                nftManager: NFTManagerMock(
                    state: .loaded(
                        .init(value: collections)
                    )
                ),
                navigationContext: NFTNavigationContextMock(),
                dependencies: NFTCollectionsListDependencies(
                    nftChainIconProvider: DummyProvider(),
                    nftChainNameProviding: NFTChainNameProviderMock(),
                    priceFormatter: NFTPriceFormatterMock(),
                    analytics: .empty,
                ),
                assetSendPublisher: .empty,
                coordinator: nil
            )
        )
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Multiple collections with loading error") {
    ZStack {
        Colors.Background.secondary
        NavigationView {
            NFTCollectionsListView(
                viewModel: .init(
                    nftManager: NFTManagerMock(
                        state: .loaded(.init(value: collections, errors: []))
                    ),
                    navigationContext: NFTNavigationContextMock(),
                    dependencies: NFTCollectionsListDependencies(
                        nftChainIconProvider: DummyProvider(),
                        nftChainNameProviding: NFTChainNameProviderMock(),
                        priceFormatter: NFTPriceFormatterMock(),
                        analytics: .empty,
                    ),
                    assetSendPublisher: .empty,
                    coordinator: nil
                )
            )
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview("Loading collections") {
    ZStack {
        Colors.Background.secondary
        NavigationView {
            NFTCollectionsListView(
                viewModel: .init(
                    nftManager: NFTManagerMock(
                        state: .loading
                    ),
                    navigationContext: NFTNavigationContextMock(),
                    dependencies: NFTCollectionsListDependencies(
                        nftChainIconProvider: DummyProvider(),
                        nftChainNameProviding: NFTChainNameProviderMock(),
                        priceFormatter: NFTPriceFormatterMock(),
                        analytics: .empty,
                    ),
                    assetSendPublisher: .empty,
                    coordinator: nil
                )
            )
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview("Failed to load collections") {
    ZStack {
        Colors.Background.secondary
        NavigationView {
            NFTCollectionsListView(
                viewModel: .init(
                    nftManager: NFTManagerMock(
                        state: .failedToLoad(error: NSError.dummy)
                    ),
                    navigationContext: NFTNavigationContextMock(),
                    dependencies: NFTCollectionsListDependencies(
                        nftChainIconProvider: DummyProvider(),
                        nftChainNameProviding: NFTChainNameProviderMock(),
                        priceFormatter: NFTPriceFormatterMock(),
                        analytics: .empty,
                    ),
                    assetSendPublisher: .empty,
                    coordinator: nil
                )
            )
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview("No Collections") {
    ZStack {
        Colors.Background.secondary
        NavigationView {
            NFTCollectionsListView(
                viewModel: .init(
                    nftManager: NFTManagerMock(state: .loaded(.init(value: []))),
                    navigationContext: NFTNavigationContextMock(),
                    dependencies: NFTCollectionsListDependencies(
                        nftChainIconProvider: DummyProvider(),
                        nftChainNameProviding: NFTChainNameProviderMock(),
                        priceFormatter: NFTPriceFormatterMock(),
                        analytics: .empty,
                    ),
                    assetSendPublisher: .empty,
                    coordinator: nil
                )
            )
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
#endif
