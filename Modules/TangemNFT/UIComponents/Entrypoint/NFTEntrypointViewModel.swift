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

public final class NFTEntrypointViewModel: ObservableObject {
    @Published private(set) var state: LoadingValue<CollectionsViewState>

    private var collections: [NFTCollection] = []
    private let nftManager: NFTManager
    private let navigationContext: NFTEntrypointNavigationContext
    private var bag: Set<AnyCancellable> = []
    private weak var coordinator: NFTEntrypointRoutable?

    public init(
        nftManager: NFTManager,
        navigationContext: NFTEntrypointNavigationContext,
        coordinator: NFTEntrypointRoutable?
    ) {
        self.nftManager = nftManager
        self.navigationContext = navigationContext
        self.coordinator = coordinator
        state = .loading

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
            let totalNFTs = collections.map(\.assetsCount).reduce(0, +)
            return Localization.nftWalletCount(totalNFTs, collections.count)

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
            let collectionsViewState = makeCollectionsViewState(from: collections.value)
            return .loaded(collectionsViewState)
        }
    }

    private func extractCollections(from managerState: NFTManagerState) -> [NFTCollection] {
        switch managerState {
        case .failedToLoad, .loading: []
        case .loaded(let collections): collections.value
        }
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

    @MainActor
    func openCollections() {
        coordinator?.openCollections(nftManager: nftManager, navigationContext: navigationContext)
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
