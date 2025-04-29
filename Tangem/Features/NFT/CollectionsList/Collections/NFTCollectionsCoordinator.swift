//
//  NFTCollectionsCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemNFT

class NFTCollectionsCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: NFTCollectionsListViewModel?

    // MARK: - Child coordinators

    @Published var assetDetailsCoordinator: NFTAssetDetailsCoordinator?

    // MARK: - Child view models

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        rootViewModel = NFTCollectionsListViewModel(
            nftManager: options.nftManager,
            chainIconProvider: options.chainIconProvider,
            coordinator: self
        )
    }
}

// MARK: - Options

extension NFTCollectionsCoordinator {
    struct Options {
        let nftManager: NFTManager
        let chainIconProvider: NFTChainIconProvider
    }
}

// MARK: - NFTReceive_Routable

extension NFTCollectionsCoordinator: NFTCollectionsListRoutable {
    func openReceive() {
        // [REDACTED_TODO_COMMENT]
    }

    func openAssetDetails(asset: NFTAsset) {
        assetDetailsCoordinator = NFTAssetDetailsCoordinator(
            dismissAction: { [weak self] in
                self?.assetDetailsCoordinator = nil
            },
            popToRootAction: { [weak self] options in
                self?.assetDetailsCoordinator = nil
                self?.popToRoot(with: options)
            }
        )
        assetDetailsCoordinator?.start(with: NFTAssetDetailsCoordinator.Options(asset: asset))
    }
}
