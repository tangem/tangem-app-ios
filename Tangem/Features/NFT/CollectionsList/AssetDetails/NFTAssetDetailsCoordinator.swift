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

final class NFTAssetDetailsCoordinator: CoordinatorObject, SendFeeCurrencyNavigating {
    let dismissAction: Action<NFTAsset?>
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

    private var options: Options?

    required init(
        dismissAction: @escaping Action<NFTAsset?>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        self.options = options

        let dependencies = NFTAssetDetailsDependencies(
            nftChainNameProvider: options.nftChainNameProvider,
            priceFormatter: options.priceFormatter,
            analytics: NFTAnalytics.Details(
                logReadMoreTapped: {
                    Analytics.log(.nftAssetReadMore)
                },
                logSeeAllTapped: {
                    Analytics.log(.nftAssetSeeAll)
                },
                logExploreTapped: {
                    Analytics.log(.nftAssetExplore)
                },
                logSendTapped: {
                    Analytics.log(.nftAssetSend)
                }
            )
        )
        rootViewModel = NFTAssetDetailsViewModel(
            asset: options.asset,
            collection: options.collection,
            dependencies: dependencies,
            coordinator: self
        )
    }

    func closeTraits() {
        traitsViewData = nil
    }

    func closeInfo() {
        extendedInfoViewData = nil
    }

    private func makeSendCoordinatorDismissActionInternal(for asset: NFTAsset) -> Action<SendCoordinator.DismissOptions?> {
        // Original action from `SendFeeCurrencyNavigating.makeSendCoordinatorDismissAction()`
        let originalAction = makeSendCoordinatorDismissAction()

        return { [weak self] dismissOptions in
            originalAction(dismissOptions)

            switch dismissOptions {
            case .closeButtonTap:
                self?.dismiss(with: asset)
            default:
                // No programmatic dismiss for other options
                break
            }
        }
    }
}

// MARK: - Options

extension NFTAssetDetailsCoordinator {
    struct Options {
        let asset: NFTAsset
        let collection: NFTCollection
        let nftChainNameProvider: NFTChainNameProviding
        let priceFormatter: NFTPriceFormatting
        let navigationInput: NFTNavigationInput
    }
}

// MARK: - NFTAssetDetailsRoutable

extension NFTAssetDetailsCoordinator: NFTAssetDetailsRoutable {
    func openSend(for asset: NFTAsset, in collection: NFTCollection) {
        guard SendFeatureProvider.shared.isAvailable, let options else {
            return
        }

        let navigationInput = options.navigationInput

        guard let walletModel = NFTWalletModelFinder.findWalletModel(for: asset, in: navigationInput.walletModelsManager.walletModels) else {
            return
        }

        let nftSendUtil = NFTSendUtil(walletModel: walletModel, userWalletModel: navigationInput.userWalletModel)
        let sendOptions = nftSendUtil.makeOptions(for: asset, in: collection)

        let coordinator = SendCoordinator(
            dismissAction: makeSendCoordinatorDismissActionInternal(for: asset),
            popToRootAction: makeSendCoordinatorPopToRootAction()
        )

        coordinator.start(with: sendOptions)
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
