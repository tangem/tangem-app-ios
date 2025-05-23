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

import Foundation
import Combine
import TangemNFT
import TangemUI

final class NFTAssetDetailsCoordinator: CoordinatorObject, FeeCurrencyNavigating {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    @Injected(\.safariManager) private var safariManager: SafariManager

    // MARK: - Root view model

    @Published private(set) var rootViewModel: NFTAssetDetailsViewModel?

    // MARK: - Child coordinators

    @Published var sendCoordinator: SendCoordinator?
    @Published var tokenDetailsCoordinator: TokenDetailsCoordinator?

    // MARK: - Child view models

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
            collection: options.collection,
            navigationContext: options.navigationContext,
            nftChainNameProviding: options.nftChainNameProviding,
            coordinator: self
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
        let collection: NFTCollection
        let navigationContext: NFTNavigationContext
        let nftChainNameProviding: NFTChainNameProviding
    }
}

// MARK: - NFTAssetDetailsRoutable

extension NFTAssetDetailsCoordinator: NFTAssetDetailsRoutable {
    func openSend(for asset: NFTAsset, in collection: NFTCollection, navigationContext: NFTNavigationContext) {
        guard
            SendFeatureProvider.shared.isAvailable,
            let input = navigationContext as? NFTNavigationInput,
            let walletModel = NFTWalletModelFinder.findWalletModel(for: asset, in: input.walletModelsManager.walletModels)
        else {
            return
        }

        let coordinator = makeSendCoordinator()
        let nftSendUtil = NFTSendUtil(walletModel: walletModel, userWalletModel: input.userWalletModel)
        let options = nftSendUtil.makeOptions(for: asset, in: collection)
        coordinator.start(with: options)
        sendCoordinator = coordinator
    }

    func openInfo(with viewData: NFTAssetExtendedInfoViewData) {
        extendedInfoViewData = viewData
    }

    func openTraits(with data: KeyValuePanelViewData) {
        traitsViewData = data
    }

    func openExplorer(for asset: NFTAsset) {
        guard let exploreURL = NFTExplorerLinkProvider().provide(for: asset.id) else {
            assertionFailure("NFT Explorer link for \(asset.id.contractAddress) on \(asset.id.chain) cannot be built")
            return
        }

        safariManager.openURL(exploreURL)
    }
}
