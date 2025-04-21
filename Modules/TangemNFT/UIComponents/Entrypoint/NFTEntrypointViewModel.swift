//
//  NFTCollectionsCompactViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemLocalization
import Foundation
import TangemFoundation

public final class NFTEntrypointViewModel: ObservableObject {
    @Published private(set) var state: LoadingValue<CollectionsViewState>
    private var collections: [NFTCollection] = []
    private let nftManager: NFTManager
    private var bag: Set<AnyCancellable> = []
    private let coordinator: NFTEntrypointRoutable

    public init(
        initialState: LoadingValue<CollectionsViewState> = .loading,
        coordinator: NFTEntrypointRoutable,
        nftManager: NFTManager
    ) {
        state = initialState
        self.nftManager = nftManager
        self.coordinator = coordinator
        bind()
    }

    var title: String {
        Localization.nftWalletTitle
    }

    var subtitle: String {
        switch state {
        case .loading:
            return ""

        case .loaded:
            let totaNFTs = collections.map(\.assetsCount).reduce(0, +)
            return Localization.nftWalletCount(totaNFTs, collections.count)

        case .failedToLoad:
            return Localization.nftWalletUnableToLoad
        }
    }

    var disabled: Bool {
        switch state {
        case .loading, .failedToLoad: true
        case .loaded: false
        }
    }

    private func bind() {
        nftManager.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                self.state = map(managerState: state)
                collections = extractCollections(from: state)
            }
            .store(in: &bag)
    }

    private func map(managerState: NFTManagerState) -> LoadingValue<CollectionsViewState> {
        switch managerState {
        case .loading:
            return .loading

        case .failedToLoad(let error):
            return .failedToLoad(error: error)

        case .loaded(let collections):
            let collectionsViewState = makeCollectionsViewState(from: collections)
            return .loaded(collectionsViewState)
        }
    }

    private func extractCollections(from managerState: NFTManagerState) -> [NFTCollection] {
        switch managerState {
        case .failedToLoad: []
        case .loading: []
        case .loaded(let collections): collections
        }
    }

    private func makeCollectionsViewState(from collections: [NFTCollection]) -> CollectionsViewState {
        switch collections.count {
        case 0:
            .noCollections

        case 1:
            .oneCollection(imageURL: collections[0].logoURL)

        case 2:
            .twoCollections(
                firstCollectionImageURL: collections[0].logoURL,
                secondCollectionImageURL: collections[1].logoURL
            )

        case 3:
            .threeCollections(
                firstCollectionImageURL: collections[0].logoURL,
                secondCollectionImageURL: collections[1].logoURL,
                thirdCollectionImageURL: collections[2].logoURL
            )

        case 4:
            .fourCollections(
                firstCollectionImageURL: collections[0].logoURL,
                secondCollectionImageURL: collections[1].logoURL,
                thirdCollectionImageURL: collections[2].logoURL,
                fourthCollectionImageURL: collections[3].logoURL
            )

        default:
            .multipleCollections(collectionsURLs: collections.map(\.logoURL))
        }
    }

    func openCollections() {
        coordinator.openCollections(nftManager)
    }
}

public extension NFTEntrypointViewModel {
    enum CollectionsViewState {
        case noCollections

        case oneCollection(imageURL: URL?)
        case twoCollections(
            firstCollectionImageURL: URL?,
            secondCollectionImageURL: URL?
        )
        case threeCollections(
            firstCollectionImageURL: URL?,
            secondCollectionImageURL: URL?,
            thirdCollectionImageURL: URL?
        )
        case fourCollections(
            firstCollectionImageURL: URL?,
            secondCollectionImageURL: URL?,
            thirdCollectionImageURL: URL?,
            fourthCollectionImageURL: URL?
        )
        case multipleCollections(collectionsURLs: [URL?])
    }
}
