//
//  NFTCollectionsCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemNFT

class NFTCollectionsCoordinator: CoordinatorObject {
    // MARK: - Navigation actions

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    private var options: Options?

    // MARK: - Root view model

    @Published private(set) var rootViewModel: NFTCollectionsListViewModel?

    // MARK: - Child coordinators

    @Published var receiveCoordinator: NFTReceiveCoordinator?
    @Published var assetDetailsCoordinator: NFTAssetDetailsCoordinator?

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        self.options = options
        rootViewModel = NFTCollectionsListViewModel(
            nftManager: options.nftManager,
            chainIconProvider: options.chainIconProvider,
            navigationContext: options.navigationContext,
            coordinator: self
        )
    }
}

// MARK: - Options

extension NFTCollectionsCoordinator {
    struct Options {
        let nftManager: NFTManager
        let chainIconProvider: NFTChainIconProvider
        let nftChainNameProviding: NFTChainNameProviding
        let navigationContext: NFTNavigationContext
    }
}

// MARK: - NFTReceive_Routable

extension NFTCollectionsCoordinator: NFTCollectionsListRoutable {
    func openReceive(navigationContext: NFTNavigationContext) {
        guard
            let input = navigationContext as? NFTNavigationInput,
            let options
        else {
            return
        }

        let coordinator = NFTReceiveCoordinator(
            dismissAction: { [weak self] in
                self?.receiveCoordinator = nil
            },
            popToRootAction: { [weak self] options in
                self?.receiveCoordinator = nil
                self?.popToRoot(with: options)
            }
        )

        coordinator.start(with: .init(input: input, nftChainNameProviding: options.nftChainNameProviding))
        receiveCoordinator = coordinator
    }

    func openAssetDetails(for asset: NFTAsset, in collection: NFTCollection, navigationContext: NFTNavigationContext) {
        let coordinator = NFTAssetDetailsCoordinator(
            dismissAction: { [weak self] in
                self?.assetDetailsCoordinator = nil
            },
            popToRootAction: { [weak self] options in
                self?.assetDetailsCoordinator = nil
                self?.popToRoot(with: options)
            }
        )

        guard let options else { return }

        coordinator.start(
            with: .init(
                asset: asset,
                collection: collection,
                navigationContext: navigationContext,
                nftChainNameProviding: options.nftChainNameProviding
            )
        )
        assetDetailsCoordinator = coordinator
    }
}
