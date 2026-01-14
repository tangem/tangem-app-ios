//
//  NFTEntrypointViewModel.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemLocalization
import TangemFoundation
import CombineExt

public final class NFTEntrypointViewModel: ObservableObject {
    @Published private(set) var state: CollectionsViewState

    private var collections: [NFTCollection] {
        nftManager.collections
    }

    private let nftManager: NFTManager
    private let accountForCollectionsProvider: AccountForNFTCollectionsProviding
    private let navigationContext: NFTNavigationContext
    private let analytics: NFTAnalytics.Entrypoint
    private var bag: Set<AnyCancellable> = []
    private var didAppear = false

    private weak var coordinator: NFTEntrypointRoutable?

    public init(
        nftManager: NFTManager,
        accountForCollectionsProvider: AccountForNFTCollectionsProviding,
        navigationContext: NFTNavigationContext,
        analytics: NFTAnalytics.Entrypoint,
        coordinator: NFTEntrypointRoutable?
    ) {
        self.nftManager = nftManager
        self.accountForCollectionsProvider = accountForCollectionsProvider
        self.navigationContext = navigationContext
        self.coordinator = coordinator
        self.analytics = analytics

        state = .noCollections
    }

    var title: String {
        Localization.nftWalletTitle
    }

    var subtitle: String {
        if collections.isEmpty {
            return Localization.nftWalletReceiveNft
        } else {
            let totalNFTs = collections.map(\.assetsCount).reduce(0, +)
            return Localization.nftWalletCountIos(totalNFTs, collections.count)
        }
    }

    func onViewAppear() {
        if didAppear {
            return
        }

        didAppear = true
        bind()
        updateInternal()
    }

    func openCollections() {
        coordinator?.openCollections(
            nftManager: nftManager,
            accountForNFTCollectionsProvider: accountForCollectionsProvider,
            navigationContext: navigationContext
        )

        let assetsWithoutCollectionCount = collections.reduce(into: 0) { sum, collection in
            if collection.id.collectionIdentifier == NFTDummyCollectionMapper.dummyCollectionIdentifier {
                sum += collection.assetsCount
            }
        }

        analytics.logCollectionsOpen(
            collections.isEmpty ? "Empty" : "Full",
            collections.count,
            collections.map(\.assetsCount).reduce(0, +),
            assetsWithoutCollectionCount
        )
    }

    private func bind() {
        nftManager
            .collectionsPublisher
            .withWeakCaptureOf(self)
            .map { viewModel, collections in
                viewModel.makeCollectionsViewState(from: collections.value)
            }
            .receiveOnMain()
            .assign(to: \.state, on: self, ownership: .weak)
            .store(in: &bag)
    }

    private func updateInternal() {
        nftManager.update(cachePolicy: .always)
    }

    private func makeCollectionsViewState(from collections: [NFTCollection]) -> CollectionsViewState {
        switch collections.count {
        case 0:
            .noCollections

        case 1:
            .oneCollection(imageURL: collections[0].media)

        case 2:
            .twoCollections(
                firstCollectionImageURL: collections[0].media,
                secondCollectionImageURL: collections[1].media
            )

        case 3:
            .threeCollections(
                firstCollectionImageURL: collections[0].media,
                secondCollectionImageURL: collections[1].media,
                thirdCollectionImageURL: collections[2].media
            )

        case 4:
            .fourCollections(
                firstCollectionImageURL: collections[0].media,
                secondCollectionImageURL: collections[1].media,
                thirdCollectionImageURL: collections[2].media,
                fourthCollectionImageURL: collections[3].media
            )

        default:
            .multipleCollections(collectionsURLs: collections.map(\.media))
        }
    }
}

extension NFTEntrypointViewModel {
    enum CollectionsViewState {
        case noCollections

        case oneCollection(imageURL: NFTMedia?)
        case twoCollections(
            firstCollectionImageURL: NFTMedia?,
            secondCollectionImageURL: NFTMedia?
        )
        case threeCollections(
            firstCollectionImageURL: NFTMedia?,
            secondCollectionImageURL: NFTMedia?,
            thirdCollectionImageURL: NFTMedia?
        )
        case fourCollections(
            firstCollectionImageURL: NFTMedia?,
            secondCollectionImageURL: NFTMedia?,
            thirdCollectionImageURL: NFTMedia?,
            fourthCollectionImageURL: NFTMedia?
        )
        case multipleCollections(collectionsURLs: [NFTMedia?])
    }
}
