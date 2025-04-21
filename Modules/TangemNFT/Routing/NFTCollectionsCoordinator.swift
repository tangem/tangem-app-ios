//
//  NFTEntrypointCoordintor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

public final class NFTCollectionsCoordinator: ObservableObject, NFTCollectionsListRoutable {
    @Published var collectionsListViewModel: NFTCollectionsListViewModel?

    private let nftManager: NFTManager
    private let chainIconProvider: NFTChainIconProvider

    public init(nftManager: NFTManager, chainIconProvider: NFTChainIconProvider) {
        self.nftManager = nftManager
        self.chainIconProvider = chainIconProvider
    }

    public func start() {
        collectionsListViewModel = NFTCollectionsListViewModel(
            nftManager: nftManager,
            chainIconProvider: chainIconProvider,
            coordinator: self
        )
    }
}
