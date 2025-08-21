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

    // MARK: - Dependencies

    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: FloatingSheetPresenter

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
        let userWalletModel = receiveInput.userWalletModel
        let dataSource = CommonNFTNetworkSelectionListDataSource(
            walletModelsManager: receiveInput.walletModelsManager,
            userWalletConfig: userWalletModel.config
        )
        rootViewModel = NFTNetworkSelectionListViewModel(
            userWalletName: userWalletModel.name,
            dataSource: dataSource,
            tokenIconInfoProvider: CommonNFTTokenIconInfoProvider(),
            nftChainNameProviding: options.nftChainNameProviding,
            analytics: options.analytics,
            coordinator: self
        )
        walletModelFinder = NFTReceiveWalletModelFinder(walletModelsManager: receiveInput.walletModelsManager)
    }
}

// MARK: - Options

extension NFTReceiveCoordinator {
    struct Options {
        let input: NFTNavigationInput
        let nftChainNameProviding: NFTChainNameProviding
        let analytics: NFTAnalytics.BlockchainSelection
    }
}

// MARK: - NFTNetworkSelectionListRoutable protocol conformance

extension NFTReceiveCoordinator: NFTNetworkSelectionListRoutable {
    func openReceive(for nftChainItem: NFTChainItem) {
        guard let walletModel = walletModelFinder?.findWalletModel(for: nftChainItem) else {
            return
        }

        let addressInfos = ReceiveFlowUtils().makeAddressInfos(from: walletModel.addresses)
        let receiveFlow: ReceiveFlow = .nft

        let receiveFlowFactory = ReceiveFlowFactory(
            flow: receiveFlow,
            tokenItem: walletModel.tokenItem,
            addressInfos: addressInfos
        )

        switch receiveFlowFactory.makeAvailabilityReceiveFlow() {
        case .bottomSheetReceiveFlow(let viewModel):
            receiveBottomSheetViewModel = viewModel
        case .domainReceiveFlow(let viewModel):
            Task { @MainActor in
                floatingSheetPresenter.enqueue(sheet: viewModel)
            }
        }
    }
}
