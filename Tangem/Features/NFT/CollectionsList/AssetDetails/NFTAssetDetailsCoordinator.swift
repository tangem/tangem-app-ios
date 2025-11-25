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
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: FloatingSheetPresenter

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

// MARK: - Navigation methods

extension NFTAssetDetailsCoordinator {
    private func startSendFlow(for asset: NFTAsset, in collection: NFTCollection, navigationContext: NFTNavigationContext) {
        guard
            let input = navigationContext as? NFTNavigationInput,
            let walletModel = NFTWalletModelFinder.findWalletModel(for: asset, in: input.walletModelsManager.walletModels)
        else {
            return
        }

        let nftSendUtil = NFTSendUtil(walletModel: walletModel, userWalletModel: input.userWalletModel)
        let options = nftSendUtil.makeOptions(for: asset, in: collection)

        let coordinator = SendCoordinator(
            dismissAction: makeSendCoordinatorDismissActionInternal(for: asset),
            popToRootAction: makeSendCoordinatorPopToRootAction()
        )

        coordinator.start(with: options)
        sendCoordinator = coordinator
    }

    private func openAccountSelector(for asset: NFTAsset, in collection: NFTCollection) {
        guard let options else { return }

        Task { @MainActor in
            floatingSheetPresenter.enqueue(
                sheet: AccountSelectorViewModel(
                    userWalletModel: options.navigationInput.userWalletModel,
                    onSelect: { [weak self] result in
                        self?.closeSheet()

                        let navigationInput = NFTNavigationInput(
                            userWalletModel: options.navigationInput.userWalletModel,
                            name: result.cryptoAccountModel.name,
                            walletModelsManager: result.cryptoAccountModel.walletModelsManager
                        )

                        self?.startSendFlow(for: asset, in: collection, navigationContext: navigationInput)
                    }
                )
            )
        }
    }

    @MainActor
    func closeSheet() {
        floatingSheetPresenter.removeActiveSheet()
    }
}

// MARK: - NFTAssetDetailsRoutable

extension NFTAssetDetailsCoordinator: NFTAssetDetailsRoutable {
    func openSend(for asset: NFTAsset, in collection: NFTCollection) {
        guard SendFeatureProvider.shared.isAvailable, let options else {
            return
        }

        if FeatureProvider.isAvailable(.accounts) {
            openAccountSelector(
                for: asset,
                in: collection
            )
        } else {
            startSendFlow(
                for: asset,
                in: collection,
                navigationContext: options.navigationInput
            )
        }
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
