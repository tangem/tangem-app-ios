//
//  NFTCollectionsCoordinator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

//
//  NFTCollectionsCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemNFT
import TangemUI
import Foundation
import BlockchainSdk

class NFTAssetDetailsCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    @Injected(\.safariManager) private var safariManager: SafariManager

    // MARK: - Root view model

    @Published private(set) var rootViewModel: NFTAssetDetailsViewModel?

    // MARK: - Child coordinators

    // MARK: - Childs

    @Published var traitsViewData: KeyValuePanelViewData?
    @Published var extendedInfoViewData: NFTAssetExtendedInfoViewData?

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        rootViewModel = NFTAssetDetailsViewModel(
            asset: options.asset,
            coordinator: self,
            nftChainNameProviding: options.nftChainNameProviding
        )
    }

    func closeTraits() {
        traitsViewData = nil
    }

    func closeInfo() {
        extendedInfoViewData = nil
    }
}

// MARK: - Options

extension NFTAssetDetailsCoordinator {
    struct Options {
        let asset: NFTAsset
        let nftChainNameProviding: NFTChainNameProviding
    }
}

// MARK: - NFTAssetDetailsRoutable

extension NFTAssetDetailsCoordinator: NFTAssetDetailsRoutable {
    func openSend() {
        // [REDACTED_TODO_COMMENT]
    }

    func openInfo(with viewData: NFTAssetExtendedInfoViewData) {
        extendedInfoViewData = viewData
    }

    func openTraits(with data: KeyValuePanelViewData) {
        traitsViewData = data
    }

    func openExplorer(for asset: NFTAsset) {
        guard let exploreURL = NFTExplorerLinkProvider().provide(for: asset) else {
            assertionFailure("NFT Explorer link for \(asset.id.assetIdentifier) on \(asset.id.chain) cannot be built")
            return
        }

        safariManager.openURL(exploreURL)
    }
}
