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
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: FloatingSheetPresenter

    // MARK: - Navigation actions

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    private var options: Options?

    // MARK: - Root view model

    @Published private(set) var rootViewModel: NFTCollectionsListViewModel?

    // MARK: - Child coordinators

    @Published var receiveCoordinator: NFTReceiveCoordinator?
    @Published var assetDetailsCoordinator: NFTAssetDetailsCoordinator?

    // MARK: - Private

    private let assetSendSubject = PassthroughSubject<NFTAsset, Never>()

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        self.options = options

        let dependencies = NFTCollectionsListDependencies(
            nftChainIconProvider: options.nftChainIconProvider,
            nftChainNameProviding: options.nftChainNameProvider,
            priceFormatter: options.priceFormatter,
            analytics: NFTAnalytics.Collections(
                logReceiveOpen: {
                    Analytics.log(.nftAssetReceiveOpened)
                },
                logDetailsOpen: { blockchain, standard in
                    Analytics.log(
                        event: .nftAssetDetailsOpened,
                        params: [.blockchain: blockchain, .nftStandard: standard]
                    )
                }
            )
        )
        rootViewModel = NFTCollectionsListViewModel(
            nftManager: options.nftManager,
            accounForNFTCollectionsProvider: options.accounForNFTCollectionsProvider,
            navigationContext: options.navigationContext,
            dependencies: dependencies,
            assetSendPublisher: assetSendSubject.eraseToAnyPublisher(),
            coordinator: self
        )
    }

    @MainActor
    func closeSheet() {
        floatingSheetPresenter.removeActiveSheet()
    }

    private func openReceive(navigationContext: NFTNavigationContext, options: Options) {
        guard let input = navigationContext as? NFTNavigationInput else {
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

        coordinator.start(
            with: .init(
                input: input,
                nftChainNameProviding: options.nftChainNameProvider,
                analytics: options.blockchainSelectionAnalytics
            )
        )
        receiveCoordinator = coordinator
    }

    private func openAccountSelector(options: Options) {
        guard let input = options.navigationContext as? NFTNavigationInput else {
            return
        }

        Task { @MainActor in
            floatingSheetPresenter.enqueue(
                sheet: AccountSelectorViewModel(
                    userWalletModel: input.userWalletModel,
                    onSelect: { [weak self] result in
                        self?.closeSheet()

                        let navigationContext = options.nftAccountNavigationContextProvider.provide(
                            for: result.cryptoAccountModel.id.toAnyHashable()
                        )

                        guard let navigationContext else {
                            return
                        }

                        self?.openReceive(navigationContext: navigationContext, options: options)
                    }
                )
            )
        }
    }
}

// MARK: - Options

extension NFTCollectionsCoordinator {
    struct Options {
        let nftManager: NFTManager
        let accounForNFTCollectionsProvider: AccountForNFTCollectionProviding
        let nftAccountNavigationContextProvider: NFTAccountNavigationContextProviding
        let nftChainIconProvider: NFTChainIconProvider
        let nftChainNameProvider: NFTChainNameProviding
        let priceFormatter: NFTPriceFormatting
        let navigationContext: NFTNavigationContext
        let blockchainSelectionAnalytics: NFTAnalytics.BlockchainSelection
    }
}

// MARK: - NFTCollectionsListRoutable

extension NFTCollectionsCoordinator: NFTCollectionsListRoutable {
    func receiveTapped() {
        guard let options else { return }

        if FeatureProvider.isAvailable(.accounts) {
            openAccountSelector(options: options)
        } else {
            openReceive(navigationContext: options.navigationContext, options: options)
        }
    }

    func openAssetDetails(for asset: NFTAsset, in collection: NFTCollection, navigationContext: NFTNavigationContext) {
        let coordinator = NFTAssetDetailsCoordinator(
            dismissAction: { [weak self] asset in
                self?.assetDetailsCoordinator = nil

                if let asset {
                    self?.assetSendSubject.send(asset)
                }
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
                nftChainNameProvider: options.nftChainNameProvider,
                priceFormatter: options.priceFormatter,
                navigationContext: navigationContext
            )
        )
        assetDetailsCoordinator = coordinator
    }
}
