//
//  NFTReceiveCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemNFT

final class NFTReceiveCoordinator: CoordinatorObject {
    // MARK: - Navigation actions

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: NFTNetworkSelectionListViewModel?

    // MARK: - Child view models

    @Published var receiveBottomSheetViewModel: ReceiveBottomSheetViewModel?

    // MARK: - Private

    private var walletModelFinder: NFTReceiveWalletModelFinder?

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        let receiveInput = options.input
        let dataSource = CommonNFTNetworkSelectionListDataSource(
            walletModelsManager: receiveInput.walletModelsManager,
            userWalletConfig: receiveInput.userWalletConfig
        )
        rootViewModel = NFTNetworkSelectionListViewModel(
            userWalletName: receiveInput.userWalletName,
            dataSource: dataSource,
            tokenIconInfoProvider: CommonNFTTokenIconInfoProvider(),
            nftChainNameProviding: options.nftChainNameProviding,
            coordinator: self
        )
        walletModelFinder = NFTReceiveWalletModelFinder(walletModelsManager: receiveInput.walletModelsManager)
    }
}

// MARK: - Options

extension NFTReceiveCoordinator {
    struct Options {
        let input: NFTReceiveInput
        let nftChainNameProviding: NFTChainNameProviding
    }
}

// MARK: - NFTNetworkSelectionListRoutable protocol conformance

extension NFTReceiveCoordinator: NFTNetworkSelectionListRoutable {
    func openReceive(for nftChainItem: NFTChainItem) {
        guard let walletModel = walletModelFinder?.findWalletModel(for: nftChainItem) else {
            return
        }

        receiveBottomSheetViewModel = ReceiveBottomSheetUtils(flow: .nft).makeViewModel(for: walletModel)
    }
}
