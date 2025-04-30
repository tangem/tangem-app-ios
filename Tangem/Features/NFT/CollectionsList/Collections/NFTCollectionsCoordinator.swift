//
//  NFTCollectionsCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemNFT

final class NFTCollectionsCoordinator: CoordinatorObject {
    // MARK: - Navigation actions

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: NFTCollectionsListViewModel?

    // MARK: - Child coordinators

    @Published var receiveCoordinator: NFTReceiveCoordinator?
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
        let navigationContext: NFTEntrypointNavigationContext
    }
}

// MARK: - NFTReceive_Routable

extension NFTCollectionsCoordinator: NFTCollectionsListRoutable {
    func openReceive(navigationContext: NFTEntrypointNavigationContext) {
        guard let receiveInput = navigationContext as? NFTReceiveInput else {
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

        receiveCoordinator = coordinator
        coordinator.start(with: .init(input: receiveInput))
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
